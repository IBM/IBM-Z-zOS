#####################################################################
#
#                     Predictive Failure Analysis (PFA)
#                        Graph Private Storage Data
#
#This python script is for use with data that is collected, created,
#and written by the PFA_PRIVATE_STORAGE_EXHAUSTION check only. Its
#use with data from any other source will result in errors.
#
#Copyright 2025 IBM Corp.                                           @01C
#                                                                   
#Licensed under the Apache License, Version 2.0 (the "License");   
#you may not use this file except in compliance with the License.  
#You may obtain a copy of the License at                           
#                                                                   
#http://www.apache.org/licenses/LICENSE-2.0                        
#                                                                   
#Unless required by applicable law or agreed to in writing,        
#software distributed under the License is distributed on an       
#"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,      
#either express or implied. See the License for the specific       
#language governing permissions and limitations under the License. 
#
# Change Activity
# $01 - Fixed issues with system not checking for "OS/390" when   @01A
#         deciding whether a gui call can be called "plt.show"
#       Dynamically Resize figure to fix Legend drawing outside of view
#       Adjusted minimum y axis value to show some seperation
#         when the value for y being plotted is very close to the 
#         x-axis
#####################################################################

import sys
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import numpy as np
import platform
import os

#Make sure we have plenty of potential data points to plot.
plt.rcParams['agg.path.chunksize']=10000
#Disable false positive warning
pd.options.mode.chained_assignment = None  # default='warn'
#Which system are we running on?
system = platform.system()

keys = {"ABOVE":"V","BELOW":"W","EAUTH":"H","AUTH":"A","EUSER":"R","USER":"U","ABV2G":"G"}
user_keys = ["ABOVE","BELOW","EAUTH","AUTH","EUSER","USER","ABV2G"]
header_data = ["Key","JobName","ASID","Start_Time","STCK_Time","Current_Usage","Date_Time","Capacity"]
check_name = "PFA_Private_Storage_Exhaustion"
types_dict = {'Key':str, 'JobName':str, 'ASID':str, 'Start_Time':str, 'STCK_Time':int, 'Current_Usage':int, 'Date_Time':str, 'Capacity':int}
JOBNAME_LEN = 8

#Parse our command line arguments.
if(len(sys.argv) == 5):
    filepath = sys.argv[1]
    jobName = sys.argv[2]
    jobName = jobName.upper()
    asid = sys.argv[3]
    asid = asid.upper()
    key = sys.argv[4]
    key = key.upper()
    verbose = False
elif(len(sys.argv) == 6 and (sys.argv[5] == '-v' or sys.argv[5] == '-verbose')):
    filepath = sys.argv[1]
    jobName = sys.argv[2]
    jobName = jobName.upper()
    asid = sys.argv[3]
    asid = asid.upper()
    key = sys.argv[4]
    key = key.upper()
    verbose = True
elif(len(sys.argv) == 2 and (sys.argv[1] == '-h' or sys.argv[1] == '-help')):
    print("The proper syntax for this script is the following:\n")
    print('python Graph_PSE_Data.py data_file_path job_name asid storage_area \n')
    print("Valid storage areas are: " + str([key for key in user_keys]) + "\n")
    print("The data_file_path is case sensitive but the other values are not. The asid must be four characters as specified on the PFA_PRIVATE_STORAGE_EXHAUSTION report.\n")
    print("For example, if this script and the required data file is in the same directory, you would specify the following to graph the EAUTH usage of JES2 with ASID 0031 on the SY1 system:\n")
    print("python Graph_PSE_Data.py SY1.5day.data jes2 0031 eauth\n")
    print("You can also add -v to the end of the command for verbose mode. This optional parameter will print additional data that could help debug errors or verify the results. An example using verbose mode looks like the following:\n")
    print("python Graph_PSE_Data.py SY1.5day.data jes2 0031 eauth -v\n")
    print("When this script is executed on z/OS, it saves the graph in a .pdf file that can be downloaded from the directory where this script was executed and displayed anywhere that supports displaying a .pdf file.")
    print("The file name is in the format of jobName_ASID_StorageLocation_graph.pdf.")
    print("For example, if you entered 'python Graph_PSE_Data.py SY1.5day.data jes2 0031 eauth' on z/OS, the saved file would be:")
    print("JES2_0031_EAUTH_graph.pdf and it would be located in the current working directory.")       
    sys.exit()
else:
    raise Exception("The supplied arguments are not correct. Specify the data_file_path, job_name, asid, and storage_location in that order. For help enter 'python Graph_PSE_Data.py -h'")

if(not os.path.exists(filepath)):
    raise Exception("The specified file or file path for the data_file_path does not exist. Verify the file and file path then try again.")

if key not in user_keys:
    raise Exception("The value specified for storage_area is not allowed. Valid storage areas are:" + str([key for key in user_keys]))

#Load up our data and assign correct header values so we can narrow it down to the pieces we want.
input = pd.read_csv(filepath,
                    sep="/|,",
                    names=header_data,
                    header=None,
                    engine="python",
                    converters=types_dict)

#We need to make sure our jobName is left justified and the proper length.
#Otherwise we will not be able to find the correct data to graph.
if(len(jobName) < JOBNAME_LEN):
    jobName = jobName.ljust(JOBNAME_LEN)

#Make sure we have proper input from the user.    
if jobName not in input.values:
    raise Exception("The specified job name does not exist. Verify the job name and try again.")

if asid not in input.values:
    raise Exception("The specified ASID does not exist for this job name. Verify the ASID and try the request again.")

user_key = key
key = keys[user_key]
NUM_TO_PRINT = 10            #This is the number of lines of data that is printed in verbose mode.
PDF_FILENAME = jobName.strip()+"_"+asid+"_"+user_key+"_graph.pdf" #This is the name of the .pdf file that gets saved when this code is ran on z/OS.

if key not in input.values:
    raise Exception("The specified storage_area does not exist. Verify the storage_area and try again.")

#Select the data we want based on the command line parms.
our_data = input.loc[(input['JobName'] == jobName) & (input['Key'] == key) & (input['ASID'] == asid)]

#Make sure we have data to graph.
if(our_data.empty):
    raise Exception("The job name and ASID combination specified didn't exist in the file or the storage area for the job name and ASID combination didn't exist in the file. Verify that the job name and asid were specified correctly or try the request again for a different storage area.")

#Format the date time info so we can use it in our graph.
our_data.loc[:,('Date_Time')] = pd.to_datetime(our_data['Date_Time'].astype(str), format='%Y%m%d%H%M%S')

#Need to verify that we are using the latest start time if multiple exist for the same ASID.
list_data = our_data['Start_Time'].to_dict()

#Here we make sure we get the latest start time.
times_dict = {}
for i in list_data:
    if list_data[i] in times_dict:
        times_dict[list_data[i]] += 1
    else:
        times_dict[list_data[i]] = 1
if(len(times_dict) > 1):
    latest_time = max(times_dict.keys())
    our_data = our_data.loc[(our_data['Start_Time'] == latest_time)]

#We potentially needed some extra blanks in our jobName to properly select our data.
#Now we need to remove those blanks so it looks better on screen and on the graph.    
jobName = jobName.strip()
#Print some extra details if verbose mode was specified.
if(verbose):
    print("Now graphing " + check_name + " data on a " + system + " system.")
    print("job_name is: " + jobName)
    print("asid is: " + asid)
    print("storage_area is: " + user_key)
    if(len(times_dict) > 1):
        print("There are " + str(len(times_dict)) + " time stamps for this job. The most recent time is always used for the graph.")
        print("The most recent time stamp for this job is: " + latest_time)
    print("\nPreview of the data being graphed: ")
    print(our_data.head(NUM_TO_PRINT).to_string(index=False))
    
#Create the values used on the y-axis of our graph and base them on the max capacity.
y_values = [0,(our_data['Capacity'].max())*.25,(our_data['Capacity'].max())*.50,(our_data['Capacity'].max())*.75,(our_data['Capacity'].max())]
if key != 'G':
    y_ticks = [str(int(y/1024)) + "KB" for y in y_values]
else:
    y_ticks = [str(int(y/1048576)) + "MB" for y in y_values]

#Graph our data
fig, ax = plt.subplots()
ax.xaxis.set_major_formatter(mdates.DateFormatter('%m-%d %H:%M'))
ax.plot(our_data['Date_Time'],our_data['Capacity'],'--r', label='Capacity')
ax.plot(our_data['Date_Time'],our_data['Current_Usage'],'-b', label='Current Usage')
plt.xlabel('Month-Day Time')
fig.suptitle(check_name + "\n" + jobName + '/' + asid + '/' + user_key, fontsize=16)
fig.autofmt_xdate()
plt.yticks(y_values, y_ticks)
ax.set_ylim(our_data['Capacity'].max()*-.01,our_data['Capacity'].max()*1.10)                                                       # @01C
legend = ax.legend(bbox_to_anchor=(1.41, 1),loc="upper right")                                                                     # @01C
#fig.tight_layout()

# Dynamically adjust figure size to accommodate the legend                                                                         # @01A
renderer = fig.canvas.get_renderer()                                                                                               # @01A
legend_bbox = legend.get_window_extent(renderer)  # Get the legend's bounding box                                                  # @01A
legend_width = legend_bbox.width / fig.dpi        # Convert legend width from pixels to inches                                     # @01A

# Get the current figure size                                                                                                      # @01A
fig_width, fig_height = fig.get_size_inches()                                                                                      # @01A

# Calculate the new figure width to fit the legend                                                                                 # @01A
new_fig_width = fig_width + legend_width                                                                                           # @01A

# Update the figure size                                                                                                           # @01A
fig.set_size_inches(new_fig_width, fig_height)                                                                                     # @01A
fig.subplots_adjust(right=0.75)
if system != 'OS/390':                                                                                                             # @01C
    plt.show();
else:
    fig.savefig(PDF_FILENAME)

if system == 'OS/390':                                                                                                             # @01C
    print(PDF_FILENAME + ' has been created and is ready to be downloaded and viewed.')
