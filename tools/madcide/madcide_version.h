// madcide_version.h — madcide's own version, tracked apart from madc's (its
// minor is the paired madc's minor − 97: madcide 0.7.0 ↔ madc 0.104.0), and
// its home page: the ONE place each is written. madcide_product.inc shows
// both in Help ▸ About; the packaging scripts and CI read them with
//     sed -n 's/^#define MADCIDE_VERSION "\(.*\)"$/\1/p' tools/madcide/madcide_version.h
#define MADCIDE_VERSION "0.9.1"
#define MADCIDE_HOME_PAGE "https://github.com/derekbsnider/madcide"
