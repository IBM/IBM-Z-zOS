#oeconsol
oeconsol is an z/OS UNIX shell commmand which allows users to issue MVS system commands and receive their responses. The command is very similar to the TSO/E CONSOLE command.
##Using oeconsol
Syntax:
oeconsol 'command'
oeconsol runs in either command or interactive mode. In command mode, an operator command is passed as a parameter to oeconsol. oeconsol executes the command, displays any command output and terminates. In interactive mode, oeconsol displays a prompt message, <OECONSOL> and waits for operator commands to be entered. Until the user enters end, oeconsol executes entered commands and displays any command output.
##Examples:
	RWJBB13:/u/rwjbb13: >oeconsol
	<OECONSOL>
	d omvs
	BPXO042I 16.50.04 DISPLAY OMVS 620
	OMVS     000E ACTIVE          OMVS=(00)
	<OECONSOL>
	end
	RWJBB13:/u/rwjbb13: >

	RWJBB13:/u/rwjbb13: >oeconsol 'd omvs'
	BPXO042I 17.05.53 DISPLAY OMVS 421
	OMVS     000E ACTIVE          OMVS=(00)
	RWJBB13:/u/rwjbb13: >
##Installing oeconsol
* Download the source code ([oeconsol.asm](https://github.com/IBM/zos-tools-and-toys/blob/master/oeconsol/oeconsol.asm))
* Make the following JCL modifications:
	* Provide a valid JOB card
	* Compete the DD card for LKED1.SYSLMOD by providing the name of an APF-authorized library that is in the LNKLST.
	* Complete the DD card for LKED2.SYSLMOD by providing the path name where oeconsol is to execute. I use /usr/local/bin which is defined in our PATH variable.
* Ensure oeconsol is either RACF program protected or the oeconsol HFS executable has the APF and program controlled extended attributes turned on.
## Controlling oeconsol
oeconsol runs as an extended MCS console whose console-name is the login userid. Use of oeconsol can be controlled through the MVS.MCSOPER.console-name profile in the RACF OPERCMDS class. Additionally, the OPERPARM segment of the login userid can be used to control the console attributes of oeconsol. For more information refer to MVS Planning: Operations.
