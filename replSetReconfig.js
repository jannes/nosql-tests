var cfg = rs.conf()
cfg.members[1].priority = 1
cfg.members[1].votes = 1
cfg.members[2].priority = 1
cfg.members[2].votes = 1
rs.reconfig(cfg)
