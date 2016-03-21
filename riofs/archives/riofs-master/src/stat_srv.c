/*
 * Copyright (C) 2012-2014 Paul Ionkin <paul.ionkin@gmail.com>
 * Copyright (C) 2012-2014 Skoobe GmbH. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */
#include "stat_srv.h"
#include "utils.h"
#include "client_pool.h"
#include "dir_tree.h"
#include "rfuse.h"
#include "cache_mng.h"

struct _StatSrv {
    Application *app;

    struct evhttp *http;
    GQueue *q_op_history;
    time_t boot_time;
};

static struct PrintFormat print_format_http = {
    "<TABLE border=1>",      // header
    "</TABLE>",     // footer
    "<HEAD><TD><B>",   // caption_start
    "</B></TD></HEAD>", // caption_end
    "<TR><TD>",     // row_start
    "</TD></TR>",   // row_end
    "</TD><TD>",     // col_div
    "</B></TD><TD><B>"     // col_div for caption
};

static void stat_srv_on_stats_cb (struct evhttp_request *req, void *ctx);
static void stat_srv_on_gen_cb (struct evhttp_request *req, void *ctx);

#define STAT_LOG "stat"

StatSrv *stat_srv_create (Application *app)
{
    StatSrv *stat_srv;

    stat_srv = g_new0 (StatSrv, 1);
    stat_srv->app = app;
    stat_srv->q_op_history = g_queue_new ();
    stat_srv->boot_time = time (NULL);

    // stats server is disabled
    if (!conf_get_boolean (application_get_conf (stat_srv->app), "statistics.enabled")) {
        return stat_srv;
    }

    stat_srv->http = evhttp_new (application_get_evbase (app));
    if (!stat_srv->http) {
        LOG_err (STAT_LOG, "Failed to create statistics server !");
        return NULL;
    }

    // bind
    if (evhttp_bind_socket (stat_srv->http,
        conf_get_string (application_get_conf (stat_srv->app), "statistics.host"),
        conf_get_int (application_get_conf (stat_srv->app), "statistics.port")) == -1) {
        LOG_err (STAT_LOG, "Failed to bind statistics server to  %s:%d",
            conf_get_string (application_get_conf (stat_srv->app), "statistics.host"),
            conf_get_int (application_get_conf (stat_srv->app), "statistics.port")
        );
        return NULL;
    }

    // install handlers
    evhttp_set_cb (stat_srv->http, conf_get_string (application_get_conf (stat_srv->app), "statistics.stats_path"), stat_srv_on_stats_cb, stat_srv);
    evhttp_set_gencb (stat_srv->http, stat_srv_on_gen_cb, stat_srv);

    return stat_srv;
}

void stat_srv_destroy (StatSrv *stat_srv)
{
    _queue_free_full (stat_srv->q_op_history, g_free);

    if (stat_srv->http)
        evhttp_free (stat_srv->http);

    g_free (stat_srv);
}

void stats_srv_add_op_history (StatSrv *stat_srv, const gchar *str)
{
    // stats server is disabled
    if (!conf_get_boolean (application_get_conf (stat_srv->app), "statistics.enabled"))
        return;

    // maintain queue size
    while (g_queue_get_length (stat_srv->q_op_history) + 1 >= conf_get_uint (application_get_conf (stat_srv->app), "statistics.history_size")) {
        gchar *tmp = g_queue_pop_tail (stat_srv->q_op_history);
        g_free (tmp);
    }

    g_queue_push_head (stat_srv->q_op_history, g_strdup (str));
}

static void stat_srv_print_history_item (gchar *s_item, GString *str)
{
    g_string_append_printf (str, "%s<BR>", s_item);
}

static void stat_srv_on_stats_cb (struct evhttp_request *req, void *ctx)
{
    StatSrv *stat_srv = (StatSrv *) ctx;
    struct evbuffer *evb = NULL;
    gint ref = 0;
    GString *str;
    struct evhttp_uri *uri;
    guint32 total_inodes, file_num, dir_num;
    guint64 read_ops, write_ops, readdir_ops, lookup_ops;
    guint32 cache_entries;
    guint64 total_cache_size, cache_hits, cache_miss;
    struct tm *cur_p;
    struct tm cur;
    time_t now;
    char ts[50];

    uri = evhttp_uri_parse (evhttp_request_get_uri (req));
    LOG_debug (STAT_LOG, "Incoming request: %s from %s:%d",
        evhttp_request_get_uri (req), req->remote_host, req->remote_port);

    if (uri) {
        const gchar *query;

        query = evhttp_uri_get_query (uri);
        if (query) {
            const gchar *refresh = NULL;
            struct evkeyvalq q_params;

            TAILQ_INIT (&q_params);
            evhttp_parse_query_str (query, &q_params);
            refresh = http_find_header (&q_params, "refresh");
            if (refresh)
                ref = atoi (refresh);

            evhttp_clear_headers (&q_params);
        }
        evhttp_uri_free (uri);
    }

    str = g_string_new (NULL);

    now = time (NULL);
    localtime_r (&now, &cur);
    cur_p = &cur;
    if (!strftime (ts, sizeof (ts), "%H:%M:%S", cur_p))
        ts[0] = '\0';

    g_string_append_printf (str, "RioFS version: %s Uptime: %u sec, Now: %s, Log level: %d, Dir cache time: %u sec<BR>",
        VERSION, (guint32)(now - stat_srv->boot_time), ts, log_level,
        conf_get_uint (application_get_conf (stat_srv->app), "filesystem.dir_cache_max_time"));

    // DirTree
    dir_tree_get_stats (application_get_dir_tree (stat_srv->app), &total_inodes, &file_num, &dir_num);
    g_string_append_printf (str, "<BR>DirTree: <BR>-Total inodes: %u, Total files: %u, Total directories: %u<BR>",
        total_inodes, file_num, dir_num);

    // Fuse
    rfuse_get_stats (application_get_rfuse (stat_srv->app), &read_ops, &write_ops, &readdir_ops, &lookup_ops);
    g_string_append_printf (str, "<BR>Fuse: <BR>-Read ops: %"G_GUINT64_FORMAT", Write ops: %"G_GUINT64_FORMAT
        ", Readdir ops: %"G_GUINT64_FORMAT", Lookup ops: %"G_GUINT64_FORMAT"<BR>",
        read_ops, write_ops, readdir_ops, lookup_ops);

    // CacheMng
    cache_mng_get_stats (application_get_cache_mng (stat_srv->app), &cache_entries, &total_cache_size, &cache_hits, &cache_miss);
    g_string_append_printf (str, "<BR>CacheMng: <BR>-Total entries: %"G_GUINT32_FORMAT", Total cache size: %"G_GUINT64_FORMAT
        " bytes, Cache hits: %"G_GUINT64_FORMAT", Cache misses: %"G_GUINT64_FORMAT" <BR>",
        cache_entries, total_cache_size, cache_hits, cache_miss);

    g_string_append_printf (str, "<BR>Read workers (%d): <BR>",
        client_pool_get_client_count (application_get_read_client_pool (stat_srv->app)));
    client_pool_get_client_stats_info (application_get_read_client_pool (stat_srv->app), str, &print_format_http);

    g_string_append_printf (str, "<BR>Write workers (%d): <BR>",
        client_pool_get_client_count (application_get_write_client_pool (stat_srv->app)));
    client_pool_get_client_stats_info (application_get_write_client_pool (stat_srv->app), str, &print_format_http);

    g_string_append_printf (str, "<BR>Op workers (%d): <BR>",
        client_pool_get_client_count (application_get_ops_client_pool (stat_srv->app)));
    client_pool_get_client_stats_info (application_get_ops_client_pool (stat_srv->app), str, &print_format_http);

    g_string_append_printf (str, "<BR><BR>Operation history (%u max items): <BR>",
        conf_get_uint (application_get_conf (stat_srv->app), "statistics.history_size"));
    g_queue_foreach (stat_srv->q_op_history, (GFunc) stat_srv_print_history_item, str);

    evb = evbuffer_new ();

    evbuffer_add_printf (evb, "<HTTP>");
    if (ref) {
        evbuffer_add_printf (evb, "<HEAD><meta http-equiv=\"refresh\" content=\"%d\"></HEAD>", ref);
    }
    evbuffer_add_printf (evb, "<BODY>");
    evbuffer_add (evb, str->str, str->len);
    evbuffer_add_printf (evb, "</BODY></HTTP>");
    evhttp_send_reply (req, HTTP_OK, "OK", evb);
    evbuffer_free (evb);

    g_string_free (str, TRUE);
}

static void stat_srv_on_gen_cb (struct evhttp_request *req, void *ctx)
{
    StatSrv *stat_srv = (StatSrv *) ctx;
    const gchar *query;

    query = evhttp_uri_get_query (evhttp_request_get_evhttp_uri (req));

    LOG_debug (STAT_LOG, "Unhandled request to: %s", query);

    (void) stat_srv;
    evhttp_send_reply (req, HTTP_NOTFOUND, "Not found", NULL);
}
