.PHONY: all run32 run64

BUILD_FILES := app32 app64 ceeuopt.o celquopt.o app32.o app64.o

vpath         $(BUILD_DIR)
vpath %.cpp   $(REPO_DIR)
vpath %.h     $(REPO_DIR)
vpath %.s     $(REPO_DIR)
vpath %.o     $(BUILD_DIR)

all: run32 run64

%.o:%.s;@ \
  printf "\nCompile $@ ...\n";\
	cd ${BUILD_DIR};\
	/bin/as -mgoff -o $@ $^;\
 	echo "rc=$$?"

%32.o:%.cpp;@\
  printf "\nCompile $@ ...\n";\
	cd ${BUILD_DIR};\
	/bin/xlC -qascii -co $@ $^;\
	echo "rc=$$?"

%64.o:%.cpp;@\
  printf "\nCompile $@ ...\n";\
	cd ${BUILD_DIR};\
	/bin/xlC -q64 -qascii -co $@ $^;\
	echo "rc=$$?"

app32: app32.o ceeuopt.o;@\
	printf "\nLink $@ usng $^ ...\n";\
	cd ${BUILD_DIR};\
	/bin/xlC -o $@ -Wl,XPLINK $^;\
	echo "rc=$$?"

app64: app64.o celquopt.o;@\
	printf "\nLink $@ usng $^ ...\n";\
	cd ${BUILD_DIR};\
	/bin/xlC -q64 -o $@ $^;\
	echo "rc=$$?"

run32: app32;@\
  printf "\nRun $^ ...\n";\
	${BUILD_DIR}/$^;\
	echo " "

run64: app64;@\
  printf "\nRun $^ ...\n";\
	${BUILD_DIR}/$^;\
	echo " "

clean:;@\
	cd ${BUILD_DIR};\
	rm -f ${BUILD_FILES}
