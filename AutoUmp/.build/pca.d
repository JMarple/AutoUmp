./.build/src/AutoUmp.xc.o: ./src/cameras/ov07740.xc
./.build/src/cameras/queue.xc.o: ./src/AutoUmp.xc ./src/cameras/detect_objects.xc ./src/cameras/ov07740.xc
./.build/src/cameras/detect_objects.xc.o: ./src/AutoUmp.xc ./src/cameras/algs.xc
./.build/src/cameras/algs.xc.o: ./src/AutoUmp.xc
./.build/src/cameras/sccb.xc.o: ./src/cameras/ov07740.xc
./.build/src/cameras/ov07740.xc.o: ./src/AutoUmp.xc
./.build/src/io/io.xc.o: /home/jmarple/code/AutoUmp/lib_locks/src/hwlock.c ./src/AutoUmp.xc ./src/cameras/algs.xc ./src/cameras/sccb.xc ./src/cameras/ov07740.xc
