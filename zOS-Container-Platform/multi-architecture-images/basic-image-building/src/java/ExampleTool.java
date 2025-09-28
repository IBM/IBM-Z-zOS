/*                                                                   */
/* Copyright 2024 IBM Corp.                                          */
/*                                                                   */
/* Licensed under the Apache License, Version 2.0 (the "License");   */
/* you may not use this file except in compliance with the License.  */
/* You may obtain a copy of the License at                           */
/*                                                                   */
/* http://www.apache.org/licenses/LICENSE-2.0                        */
/*                                                                   */
/* Unless required by applicable law or agreed to in writing,        */
/* software distributed under the License is distributed on an       */
/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,      */
/* either express or implied. See the License for the specific       */
/* language governing permissions and limitations under the License. */
/*                                                                   */
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.FileSystems;
import java.nio.file.Path;

public class ExampleTool {

    public static void main(String[] args) {
        
        // Error code for failures
        final int ERROR = 1;

        // Parse arguments
        if (args.length != 2 || ! args[0].equals("--input")) {
            System.err.println("Invalid arguments.");
            System.err.println("Usage: java ExampleTool --input <input-file>");
            System.exit(ERROR);
        }

        // Read input file contents
        Path inPath = FileSystems.getDefault().getPath(args[1]);
        String inputContents = "";
        try { 
            inputContents = new String(Files.readAllBytes(inPath));
        } catch(IOException e) {
            System.err.println("Failed to read input file: " + inPath);
            System.exit(ERROR);
        }

        System.out.println(inputContents);
    }

}