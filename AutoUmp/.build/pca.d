.build/src/cameras/algs.xc.o: ./src/AutoUmp.xc
.build/src/cameras/ov07740.xc.o: ./src/AutoUmp.xc
.build/src/io/io.xc.o: /home/tbadams45/XMOS/autoump/lib_locks/src/hwlock.c ./src/AutoUmp.xc ./src/cameras/algs.xc ./src/cameras/ov07740.xc ./src/cameras/sccb.xc
.build/src/cameras/detect_objects.xc.o: ./src/cameras/algs.xc
.build/src/cameras/queue.xc.o: ./src/AutoUmp.xc ./src/cameras/detect_objects.xc
.build/src/cameras/sccb.xc.o: ./src/cameras/ov07740.xc
