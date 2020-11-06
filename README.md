## Minimum size standalone transport tracer run directory


Stats:
- Memory requirement: < 1GB
- Wall time: ~20 seconds

Running:
```shell
$ git clone https://github.com/LiamBindle/minimum_standalone_transport_tracer.git
$ cd minimum_standalone_transport_tracer/v2020-11
$ mpirun -np 6 gchp
```

Validation:
```shell
$ ncks --chk_nan OutputDir/GCHP.SpeciesConc.*.nc4
```

