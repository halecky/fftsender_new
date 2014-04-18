#ifndef RADAR_H
#define RADAR_H

#include<eudp.h>

/**Radar object declaration*/
typedef struct rdr_t {
  eudp_t udp;

  char addr[16];
  int port;

  char *pkt;
  int pkt_sz;

  int (*coll_fn)(struct rdr_t *rdr, void *coll, int coll_sz, void *arg);

  int rcv_tmo;
} rdr_t;

void rdr_init(rdr_t *rdr, char *addr, int port, int rcv_tmo, int pkt_sz,
	      int (*coll_fn)(rdr_t *rdr, void *coll, int coll_sz, void *arg));
void rdr_deinit(rdr_t *rdr);

void rdr_conn(rdr_t *rdr);
void rdr_disconn(rdr_t *rdr);

int rdr_recv_pkt(rdr_t *rdr);
int rdr_collect_pkts(rdr_t *rdr, void *coll, int coll_sz, void *arg);

char *rdr_get_pkt(rdr_t *rdr);
int rdr_get_pkt_sz(rdr_t *rdr);

#endif

