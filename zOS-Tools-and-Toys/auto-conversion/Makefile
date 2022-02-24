###################################################################
# Copyright 2022 IBM Corp.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
#  either express or implied. See the License for the specific
#  language governing permissions and limitations under the
#  License.
#
# -----------------------------------------------------------------
#
# Disclaimer of Warranties:
#
#   The following enclosed code is sample code created by IBM
#   Corporation.  This sample code is not part of any standard
#   IBM product and is provided to you solely for the purpose
#   of assisting you in the development of your applications.
#   The code is provided "AS IS", without warranty of any kind.
#   IBM shall not be liable for any damages arising out of your
#   use of the sample code, even if they have been advised of
#   the possibility of such damages.
#
# -----------------------------------------------------------------
###################################################################

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
