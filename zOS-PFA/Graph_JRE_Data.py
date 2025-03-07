#####################################################################
#
#                     Predictive Failure Analysis (PFA)
#                        Graph JES2 Resource Data
#
#This python script is for use with data that is collected, created,
#and written by the PFA_JES2_RESOURCE_EXHAUSTION check only. Its
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
#       Fixed dividing by 1024 unnecessarily for Current Usage
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

keys = {"JQE":"Q","SPOOL":"S","BERT":"B","JOE":"J"}
user_keys = ["JQE","SPOOL","BERT","JOE"]
resource_header_data = ["Resource","STCK_Time","Current_Usage","Date_Time"]
capacity_header_data = ["Resource","Capacity"]
check_name = "PFA_JES2_Resource_Exhaustion"
COLUMN_CHAR_LEN = 8

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
    print("'python Graph_JRE_Data.py data_file capacity_file jes2_resource'.\n")
    print("Valid JES2 Resources are: "+ str([key for key in user_keys]) + '\n')
    print("The file path values are case sensitive, but the JES2 resource is not.\n")
    print("For example, if this script and the required files are in the same directory, you would specify the following to graph the JES2 Spool data on system SY1:\n")
    print("'python Graph_JRE_Data.py SY1.5day.data SY1.capacity SPOOL'\n")
    print("You can also add -v to the end of the command for verbose mode. This option will print additional data ")
    print("that could help debug errors or verify the results. An example using verbose mode looks like the following:\n")
    print("'python Graph_JRE_Data.py SY1.5day.data Capacity.data BERT -v'\n")
    print("When this script is executed on z/OS, it saves the graph in a .pdf file that can be downloaded from the directory where this script was executed and displayed anywhere that supports displaying a .pdf file.")
    print("The file name is in the format of JESResource_graph.pdf.")
    print("For example, if you entered 'python Graph_JRE_Data.py SY1.5day.data SY1.capacity SPOOL' on z/OS the saved file would be:")
    print("SPOOL_graph.pdf and it would be located in the current working directory.")
    sys.exit()
else:
    raise Exception("The supplied arguments are not correct. Specify the data_file_path, capacity_file_path, and JES2 resource in that order. For help enter 'python Graph_JRE_Data.py -h'")

#Make sure we have proper input from the user.
if(not os.path.exists(data_filepath)):
    raise Exception("The specified file or filepath for the data file does not exist. Verify the file and filepath then try again.")

if(not os.path.exists(capacity_filepath)):
    raise Exception("The specified file or filepath for the capacity file does not exist. Verify the file and filepath then try again.")

if key not in user_keys:
    raise Exception("The specified resource does not exist. Specify a resource that exists.")

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
user_key = user_key.ljust(COLUMN_CHAR_LEN)
data_file = data_file.join(capacity_file["Capacity"])
NUM_TO_PRINT = 10
PDF_FILENAME = user_key.strip()+"_graph.pdf"  #This is the name of the .pdf file that gets saved when this script is ran on z/OS

def process_data(data_file, capacity_file):
    the_capacity = capacity_file.loc[capacity_file['Resource'] == user_key,'Capacity'].values[0]
    the_data = data_file.loc[data_file['Resource'] == user_key]
    the_data['Capacity'].fillna(the_capacity, inplace=True)
    the_data['Capacity'] = the_data['Capacity'].astype(int)
    the_data.loc[:,('Date_Time')] = pd.to_datetime(the_data['Date_Time'].astype(str), format='%Y%m%d%H%M%S')
    if(verbose):
        print_details(the_data, NUM_TO_PRINT)
    return the_data

def graph_data(the_data):
    y_values = [0,(the_data['Capacity'].max())*.25,(the_data['Capacity'].max())*.50,(the_data['Capacity'].max())*.75,(the_data['Capacity'].max())]
    y_ticks = [str(int(y)) for y in y_values]
    fig, ax = plt.subplots()
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%m-%d %H:%M'))
    ax.set_ylim(the_data['Capacity'].max()*-.01,the_data['Capacity'].max()*1.10)                                                   # @01C
    ax.plot(the_data['Date_Time'],the_data['Capacity'],'--r', label='Capacity')
    ax.plot(the_data['Date_Time'],the_data['Current_Usage'],'-b', label='Current Usage')                                           # @01C
    fig.suptitle(check_name + "\n" + user_key, fontsize=16)
    plt.yticks(y_values, y_ticks)
    plt.xlabel('Month-Day Time')    
    fig.autofmt_xdate()    
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
    print("JES2 resource is: " + user_key.strip())
    print("data_filepath entered: " + data_filepath)
    print("capacity_filepath entered was: " + capacity_filepath)
    print("\nPreview of the data being graphed:")
    print(data_frame.head(num_to_print).to_string(index=False))
 
#Process and graph our data.
the_data = process_data(data_file, capacity_file)
user_key = user_key.strip()
graph_data(the_data)    

if system == 'OS/390':                                                                                                             # @01C
    print(PDF_FILENAME + ' has been created and is ready to be downloaded and viewed.')
