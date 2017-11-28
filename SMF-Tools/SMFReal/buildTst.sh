#!/bin/sh                                                                       
                                                                                
# Build the 64-bit smfreal test                                                 
# This script will also generate listings in:                                   
# smfreal.lst and smfreal_2.lst                                                 

# ** Beginning of Copyright and License **
#
# Copyright 2017 IBM Corp.                                           
#                                                                    
# Licensed under the Apache License, Version 2.0 (the "License");    
# you may not use this file except in compliance with the License.   
# You may obtain a copy of the License at                            
#                                                                    
# http://www.apache.org/licenses/LICENSE-2.0                         
#                                                                   
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS,  
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  
# See the License for the specific language governing permissions and  
# limitations under the License.                    
#
# ** End of Copyright and License **        
                                                                                
c89 \                                                                           
   -V \                                                                         
   -O \                                                                         
   -o smfreal \                                                                 
   -W c,'lp64,xplink,list,sscom,langlvl(extended),noansialias' \                
   -W l,'lp64,xplink,amode=64' \                                                
   -I . \                                                                       
   smfreal.c \                                                                  
   >smfreal.lst 2>smfreal_2.lst                                                 
                                                                                
