#####################################################################
#
#                     Predictive Failure Analysis (PFA)
#                        Graph Common Storage ASIDs
#
#This python script is for use with data that is collected, created,
#and written by the PFA_COMMON_STORAGE_USAGE check only. Its
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
# $01 - Fixed issues with system not checking for "OS/390" when      @01A
#         deciding whether a gui call can be called "plt.show"
#       Added support for passing the sysname.allData when the 
#         systemName.5day.All.data is not available.
#       Adjusted minimum y axis value to show some seperation
#         when the value for y being plotted is very close to the 
#         x-axis
#       Dynamically Resize figure to fix Legend drawing outside of view
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

keys = {"CSA":"C","SQA":"S","ECSA":"E","ESQA":"Q"}
user_keys = ["CSA","SQA","ECSA","ESQA"]
resource_header_data = ["Location","JobName","ASID","Start_Time","STCK_Time","Current_Usage","Date_Time"]
capacity_header_data = ["Key","Location","Capacity"]
check_name = "PFA_Common_Storage_Usage"
data_types_dict={'Location':str,'JobName':str,'ASID':str,'Start_Time':str,'STCK_Time':int,'Current_Usage':int,'Date_Time':str}
capacity_types_dict={"Key":str,"Location":str,"Capacity":int}
COLUMN_CHAR_LEN = 8
file5d_fp = 0                                                                                                                      # @01A

#Parse our command line arguments.
if(len(sys.argv) == 6):
    data_filepath = sys.argv[1]
    capacity_filepath = sys.argv[2]
    jobName = sys.argv[3]
    jobName = jobName.upper()
    asid = sys.argv[4]
    asid = asid.upper()    
    key = sys.argv[5]
    key = key.upper()
    verbose = False
elif(len(sys.argv) == 7 and (sys.argv[6] == '-v' or sys.argv[6] == '-verbose')):
    data_filepath = sys.argv[1]
    capacity_filepath = sys.argv[2]
    jobName = sys.argv[3]
    jobName = jobName.upper()
    asid = sys.argv[4]
    asid = asid.upper()    
    key = sys.argv[5]
    key = key.upper()
    verbose = True
elif(len(sys.argv) == 2 and (sys.argv[1] == '-h' or sys.argv[1] == '-help')):
    print("The proper syntax for this script is the following:\n")
    print("python Graph_CSU_Asid.py data_file_path capacity_file_path job_name asid storage_location optional_parameters \n")
    print("Valid storage locations are: " + str([key for key in user_keys]) + "\n")
    print("The data_file_path and the capacity_file_path are case sensitive. The asid must be four characters as specified on the PFA_COMMON_STORAGE_USAGE report.\n")
    print("For example, if this script and the required files are in the same directory, you would specify the following to graph the CSA usage of JES2 with ASID 0031 from the SY1 system:\n")
    print("'python Graph_CSU_Asid.py SY1.5day.All.data SY1.capacity JES2 0031 CSA' \n")
    print("You can also add -v to the end of the command for verbose mode. This optional parameter will print additional data that could help debug errors or verify the results. An example using verbose mode looks like the following:\n")
    print("'python Graph_CSU_Asid.py SY1.5day.All.data SY1.capacity JES2 0031 CSA -v' \n")
    print("When this script is executed on z/OS, it saves the graph in a .pdf file that can be downloaded from the directory where this script was executed and displayed anywhere that supports displaying a .pdf file.")
    print("The file name is in the format of jobName_ASID_StorageLocation_graph.pdf.")
    print("For example, if you entered 'python Graph_CSU_Asid.py SY1.5day.All.data SY1.capacity JES2 0031 CSA' on z/OS the saved file would be:")
    print("JES2_0031_CSA_graph.pdf and it would be located in the current working directory.")
    sys.exit()
else:
    raise Exception("The supplied arguments are not correct. Specify the data_file_path, capacity_file_path, job_name, asid, and storage_location in that order. For help enter 'python Graph_CSU_Asid.py -h'")

if(not os.path.exists(data_filepath)):
    raise Exception("The specified file or file path for the data file does not exist. Verify the file and file path then try again.")

if(not os.path.exists(capacity_filepath)):
    raise Exception("The specified file or file path for the capacity file does not exist. Verify the file and file path then try again.")

if key not in user_keys:
    raise Exception("The specified storage_location is not allowed. Valid storage locations are:" + str([key for key in user_keys]))

if "5day" in data_filepath:                                                                                                        # @01A
    file5d_fp = 1                                                                                                                  # @01A

#Load up our data and assign correct header values so we can narrow it down to the pieces we want.
data_file = pd.read_csv(data_filepath,
                    sep="/|,",
                    names=resource_header_data,
                    header=None,
                    engine="python",
                    converters=data_types_dict)

capacity_file = pd.read_csv(capacity_filepath,
                    sep="/|,",
                    names=capacity_header_data,
                    header=None,
                    engine="python",
                    converters=capacity_types_dict)

#We need to make sure our jobName is left justified and the proper length.
#Otherwise we will not be able to find the correct data to graph.
if(len(jobName) < COLUMN_CHAR_LEN):
    jobName = jobName.ljust(COLUMN_CHAR_LEN)
    
if jobName not in data_file.values:
    raise Exception("The specified job name does not exist. Verify the job name and try again.")

if asid not in data_file.values:
    raise Exception("The specified ASID does not exist for this job name. Verify the ASID and try the request again.")

user_key = key
key = keys[user_key]
if key not in data_file.values:
    raise Exception("The specified storage_location does not exist. Verify the storage_location and try again.")

data_file['Capacity'] = np.nan 
NUM_TO_PRINT = 10
PDF_FILENAME = jobName.strip()+"_"+asid+"_"+user_key+"_graph.pdf"  #This is the name of the .pdf file that gets saved when this script is ran on z/OS

def process_data(data_file, capacity_file):
    the_capacity = capacity_file.loc[capacity_file['Key'] == key,'Capacity'].values[0]
    the_data = data_file.loc[(data_file['JobName'] == jobName) & (data_file['Location'] == key) & (data_file['ASID'] == asid)]
    validate_df(the_data)
    the_data['Capacity'].fillna(the_capacity, inplace=True)
    the_data['Capacity'] = the_data['Capacity'].astype(int)
    the_data.loc[:,('Date_Time')] = pd.to_datetime(the_data['Date_Time'].astype(str), format='%Y%m%d%H%M%S')
    the_data = get_latest_start_time(the_data)
    if(verbose):
        print_details(the_data, NUM_TO_PRINT)
    return the_data

def graph_data(the_data):
    y_values = [0,(the_data['Capacity'].max())*.25,(the_data['Capacity'].max())*.50,(the_data['Capacity'].max())*.75,(the_data['Capacity'].max())]
    y_ticks = [str(int(y)) + "KB" for y in y_values]
    fig, ax = plt.subplots()
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%m-%d %H:%M'))
    ax.plot(the_data['Date_Time'],the_data['Capacity'],'--r', label='Capacity')
    if file5d_fp == 1:                                                                                                             # @01A
        ax.plot(the_data['Date_Time'],the_data['Current_Usage']/1024,'-b', label='Current Usage')
    else:                                                                                                                          # @01A
        ax.plot(the_data['Date_Time'],the_data['Current_Usage'],'-b', label='Current Usage')                                       # @01A
    plt.xlabel('Month-Day Time')
    fig.suptitle(check_name + "\n" + jobName + '/' + asid + '/' + user_key, fontsize=16)
    fig.autofmt_xdate()
    plt.yticks(y_values, y_ticks)
    ax.set_ylim(the_data['Capacity'].max()*-.01,the_data['Capacity'].max()*1.10)                                                   # @01C
    legend = ax.legend(bbox_to_anchor=(1.41, 1),loc="upper right")                                                                 # @01C
    # Dynamically adjust figure size to accommodate the legend                                                                     # @01A
    renderer = fig.canvas.get_renderer()                                                                                           # @01A
    legend_bbox = legend.get_window_extent(renderer)  # Get the legend's bounding box                                              # @01A
    legend_width = legend_bbox.width / fig.dpi        # Convert legend width from pixels to inches                                 # @01A

    # Get the current figure size                                                                                                  # @01A
    fig_width, fig_height = fig.get_size_inches()                                                                                  # @01A

    # Calculate the new figure width to fit the legend                                                                             # @01A
    new_fig_width = fig_width + legend_width                                                                                       # @01A

    # Update the figure size                                                                                                       # @01A
    fig.set_size_inches(new_fig_width, fig_height)                                                                                 # @01A    
    fig.subplots_adjust(right=0.75)
    if system != 'OS/390':                                                                                                         # @01C
        plt.show();
    else:             
        fig.savefig(PDF_FILENAME)

def print_details(data_frame, num_to_print):
    print("Now graphing " + check_name + " data on a " + system + " system.")
    print("job_name is: " + jobName)    
    print("storage_location is: " + user_key)
    print("asid is: " + asid)
    print("data_filepath entered: " + data_filepath)
    print("capacity_filepath entered was: " + capacity_filepath)
    print("\nPreview of the data being graphed:")
    print(data_frame.head(num_to_print).to_string(index=False))

def get_latest_start_time(data_frame):
    list_data = data_frame['Start_Time'].to_dict()
    times_dict = {}
    for i in list_data:
        if list_data[i] in times_dict:
            times_dict[list_data[i]] += 1
        else:
            times_dict[list_data[i]] = 1
    if(len(times_dict) > 1):
        latest_time = max(times_dict.keys())
        data_frame = data_frame.loc[(data_frame['Start_Time'] == latest_time)]
    return data_frame     

def validate_df(data_frame):
    if(data_frame.empty):
        raise Exception("The job name and ASID combination specified didn't exist in the file or the storage location for the job name and ASID combination didn't exist in the file. Verify that the job name and asid were specified correctly or try the request again for a different storage location.")
    return

#Process and graph our data. 
the_data = process_data(data_file, capacity_file)
jobName = jobName.strip()
graph_data(the_data)

if system == 'OS/390':                                                                                                             # @01C
    print(PDF_FILENAME + ' has been created and is ready to be downloaded and viewed.')    
