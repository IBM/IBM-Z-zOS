#####################################################################
#
#                     Predictive Failure Analysis (PFA)
#                        Graph Common Storage Data
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
# $01 - Fixed issues with system not checking for "OS/390" when   @01A
#         deciding whether a gui call can be called "plt.show"
#       Added support for passing the sysname.Data when the 
#         systemName.5day.data is not available.
#       Adjusted minimum y axis value to show some seperation
#         when the value for y being plotted is very close to the 
#         x-axis
#       Fixed missing Legend Labels for invocation with ECSA+ESQA
#       Fixed overlapping ECSA heading with category ECSA+ESQA title
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

keys = {"CSA":"C","SQA":"S","CSA+SQA":"B","ECSA":"E","ESQA":"Q","ECSA+ESQA":"A"}
user_keys = ["CSA","SQA","CSA+SQA","ECSA","ESQA","ECSA+ESQA"]
resource_header_data = ["Key","Location","STCK_Time","Current_Usage","Date_Time"]
capacity_header_data = ["Key","Location","Capacity"]
check_name = "PFA_Common_Storage_Usage"
SQUAD_A_USERKEYS = {0:'ECSA',1:'ESQA',2:'ECSA+ESQA'}
SQUAD_B_USERKEYS = {0:'CSA',1:'SQA',2:'CSA+SQA'}
SQUAD_A_KEYS = {0:'E',1:'Q',2:'A'}
SQUAD_B_KEYS = {0:'C',1:'S',2:'B'}
file5d_fp = 0                                                                                                                      # @01A

#Parse our command line arguments.
if(len(sys.argv) == 4):
    data_filepath = sys.argv[1]
    capacity_filepath = sys.argv[2]    
    key = sys.argv[3]
    key = key.upper()
    verbose = False
elif(len(sys.argv) == 5 and (sys.argv[4] == '-v' or sys.argv[4] == '-verbose')):
    data_filepath = sys.argv[1]
    capacity_filepath = sys.argv[2]    
    key = sys.argv[3]
    key = key.upper()
    verbose = True
elif(len(sys.argv) == 2 and (sys.argv[1] == '-h' or sys.argv[1] == '-help')):
    print("The proper syntax for this script is the following:\n")
    print("python Graph_CSU_Data.py data_file_path capacity_file_path storage_location optional_parameters \n")
    print("Valid storage locations are: " + str([key for key in user_keys]) + "\n")
    print("The data_file_path and the capacity_file_path are case sensitive.\n")
    print("For example, if this script and the required files are in the same directory, you would specify the following to graph the CSA usage of the SY1 system:\n")
    print("'python Graph_CSU_Data.py SY1.5day.data SY1.capacity CSA' \n")
    print("You can also add -v to the end of the command for verbose mode. This optional parameter will print additional data that could help debug errors or verify the results. An example using verbose mode looks like the following:\n")
    print("'python Graph_CSU_Asid.py SY1.5day.data SY1.capacity CSA -v' \n")
    print("When this script is executed on z/OS, it saves the graph in a .pdf file that can be downloaded from the directory where this script was executed and displayed anywhere that supports displaying a .pdf file.")
    print("The file name is in the format of StorageLocation_graph.pdf.")
    print("For example, if you entered 'python Graph_CSU_Data.py SY1.5day.data SY1.capacity CSA' on z/OS the saved file would be:")
    print("CSA_graph.pdf and it would be located in the current working directory.")    
    sys.exit()
else:
    raise Exception("The supplied arguments are not correct. Specify the data_file_path, capacity_file_path, and storage_location in that order. For help enter 'python Graph_CSU_Data.py -h'")

#Make sure we have proper input from the user.
if(not os.path.exists(data_filepath)):
    raise Exception("The specified file or filepath for the data file does not exist. Verify the file and filepath then try again.")

if(not os.path.exists(capacity_filepath)):
    raise Exception("The specified file or filepath for the capacity file does not exist. Verify the file and filepath then try again.")

if key not in user_keys:
    raise Exception("The specified storage_location is not allowed. Valid storage locations are:" + str([key for key in user_keys]))

if "5day" in data_filepath:                                                                                                        # @01A
    file5d_fp = 1                                                                                                                  # @01A

#Load up our data and assign correct header values so we can narrow it down to the pieces we want.
data_file = pd.read_csv(data_filepath,
                    sep="/|,",
                    names=resource_header_data,
                    header=None,
                    engine="python")

capacity_file = pd.read_csv(capacity_filepath,
                    sep="/|,",
                    names=capacity_header_data,
                    header=None,
                    engine="python")

user_key = key
key = keys[user_key]

if key not in data_file.values:
    raise Exception("The specified storage_location does not exist. Verify the storage_location and try again.")

data_file['Capacity'] = np.nan 
NUM_TO_PRINT = 10
PDF_FILENAME = user_key+"_graph.pdf" #This is the name of the .pdf file that gets saved when this script is ran on z/OS

def process_data(data_file, capacity_file,key,user_key):
    the_capacity = capacity_file.loc[capacity_file['Key'] == key,'Capacity'].values[0]
    the_data = data_file.loc[data_file['Key'] == key]
    the_data['Capacity'].fillna(the_capacity, inplace=True)
    the_data['Capacity'] = the_data['Capacity'].astype(int)
    the_data.loc[:,('Date_Time')] = pd.to_datetime(the_data['Date_Time'].astype(str), format='%Y%m%d%H%M%S')
    if(verbose):
        print_details(the_data, NUM_TO_PRINT)    
    return the_data

def graph_data(the_data):
    the_y_values, y_ticks = process_yvalues_yticks(the_data)
    fig, ax = plt.subplots()
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%m-%d %H:%M'))
    ax.plot(the_data['Date_Time'],the_data['Capacity'],'--r', label='Capacity')
    if file5d_fp == 1:                                                                                                             # @01A
        ax.plot(the_data['Date_Time'],the_data['Current_Usage']/1024,'-b', label='Current Usage')
    else:                                                                                                                          # @01A  
        ax.plot(the_data['Date_Time'],the_data['Current_Usage'],'-b', label='Current Usage')                                       # @01A
    plt.xlabel('Month-Day Time')
    fig.suptitle(check_name + "\n" + user_key, fontsize=16)
    fig.autofmt_xdate()
    plt.yticks(the_y_values, y_ticks)
    ax.set_ylim(the_data['Capacity'].max()*-.01,the_data['Capacity'].max()*1.10)                                                   # @01C
    legend = ax.legend(bbox_to_anchor=(1.41, 1),loc="upper right")                                                                 # @01C 
    adjust_figure_size(legend,fig)                                                                                                 # @01A 
    fig.subplots_adjust(right=0.75)
    if system != 'OS/390':                                                                                                         # @01C
        plt.show();
    else:
        fig.savefig(PDF_FILENAME)

def graph_total_data(the_data,squad_userkeys):
    fig, axes = plt.subplots(nrows = len(the_data), ncols = 1,sharex = True)
    y_values = {}
    y_ticks = {}
    for i in range(len(the_data)):
        y_values[i], y_ticks[i] = process_yvalues_yticks(the_data[i])    
        axes[i].xaxis.set_major_formatter(mdates.DateFormatter('%m-%d %H:%M'))
        axes[i].set_ylim(the_data[i]['Capacity'].max()*-.01,the_data[i]['Capacity'].max()*1.10)                                    # @01C
        axes[i].plot(the_data[i]['Date_Time'],the_data[i]['Capacity'],'--r', label='Capacity')
        if file5d_fp == 1:                                                                                                         # @01A
            axes[i].plot(the_data[i]['Date_Time'],the_data[i]['Current_Usage']/1024,'-b', label='Current Usage')
        else:                                                                                                                      # @01A 
            axes[i].plot(the_data[i]['Date_Time'],the_data[i]['Current_Usage'],'-b', label='Current Usage')                        # @01A
        axes[i].set_title(squad_userkeys[i])
        axes[i].set_yticks(y_values[i], y_ticks[i])    
        plt.sca(axes[i])
        plt.yticks(y_values[i], y_ticks[i])
        axes[i].tick_params(axis='both', which='both',labelsize=7)
    for tick in axes[0].get_xticklabels():
        tick.set_visible(True)
    plt.xlabel('Month-Day Time')
    fig.suptitle(check_name + " - " + user_key + "\n" + "\n" , fontsize=16)                                                        # @01C
    fig.autofmt_xdate()    
                                                                                                                                   # @01D                                                                     
    legend = axes[0].legend(bbox_to_anchor=(1.41, 1),loc="upper right")                                                            # @01A
    adjust_figure_size(legend,fig)
    fig.subplots_adjust(right=0.75)                                                                                                # @01A
    if system != 'OS/390':                                                                                                         # @01C
        plt.show();
    else:
        fig.savefig(PDF_FILENAME)

def adjust_figure_size(legend,fig):
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

def process_yvalues_yticks(data_file):
    y_values = [0,(data_file['Capacity'].max())*.25,(data_file['Capacity'].max())*.50,(data_file['Capacity'].max())*.75,(data_file['Capacity'].max())]
    y_ticks = [str(int(y)) + "KB" for y in y_values]
    return y_values, y_ticks

def print_details(data_frame, num_to_print):
    print("Now graphing " + check_name + " data on a " + system + " system.")   
    print("storage_location is: " + user_key)
    print("data_file_path entered: " + data_filepath)
    print("capacity_file_path entered was: " + capacity_filepath)
    print("\nPreview of the data being graphed:")
    print(data_frame.head(NUM_TO_PRINT).to_string(index=False))
 
data_collection = {}
#Process and graph our data.
if key == 'A':  #ECSA+ESQA
    for i in range(3):
        data_collection[i] = process_data(data_file, capacity_file, SQUAD_A_KEYS[i], SQUAD_A_USERKEYS[i])
    graph_total_data(data_collection, SQUAD_A_USERKEYS)
    
elif key == 'B':  #CSA+SQA
    for i in range(3):
        data_collection[i] = process_data(data_file, capacity_file, SQUAD_B_KEYS[i], SQUAD_B_USERKEYS[i])
    graph_total_data(data_collection, SQUAD_B_USERKEYS)
    
else:
    the_data = process_data(data_file, capacity_file, key, user_key)
    graph_data(the_data)

if system == 'OS/390':                                                                                                             # @01C
    print(PDF_FILENAME + ' has been created and is ready to be downloaded and viewed.')
