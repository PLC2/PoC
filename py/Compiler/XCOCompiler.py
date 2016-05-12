# EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t; python-indent-offset: 2 -*-
# vim: tabstop=2:shiftwidth=2:noexpandtab
# kate: tab-width 2; replace-tabs off; indent-width 2;
# 
# ==============================================================================
# Authors:          Patrick Lehmann
#                   Martin Zabel
# 
# Python Class:      This XCOCompiler compiles xco IPCores to netlists
# 
# Description:
# ------------------------------------
#		TODO:
#		- 
#		- 
#
# License:
# ==============================================================================
# Copyright 2007-2016 Technische Universitaet Dresden - Germany
#                     Chair for VLSI-Design, Diagnostics and Architecture
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
#
# entry point
if __name__ != "__main__":
	# place library initialization code here
	pass
else:
	from lib.Functions import Exit
	Exit.printThisIsNoExecutableFile("The PoC-Library - Python Module Compiler.XCOCompiler")

	
# load dependencies
import shutil
from os                      import chdir
from pathlib                import Path
from textwrap                import dedent

from Base.Project            import ToolChain, Tool
from Base.Compiler          import Compiler as BaseCompiler, CompilerException, SkipableCompilerException
from PoC.Entity              import WildCard
from ToolChains.Xilinx.ISE  import ISE, ISEException


class Compiler(BaseCompiler):
	_TOOL_CHAIN =  ToolChain.Xilinx_ISE
	_TOOL =        Tool.Xilinx_CoreGen

	def __init__(self, host, dryRun, noCleanUp):
		super().__init__(host, dryRun, noCleanUp)

		self._toolChain =    None

		configSection = host.PoCConfig['CONFIG.DirectoryNames']
		self.Directories.Working = host.Directories.Temp / configSection['ISECoreGeneratorFiles']
		self.Directories.Netlist = host.Directories.Root / configSection['NetlistFiles']

		self._PrepareCompiler()

	def _PrepareCompiler(self):
		self._LogVerbose("Preparing Xilinx Core Generator Tool (CoreGen).")
		iseSection = self.Host.PoCConfig['INSTALL.Xilinx.ISE']
		binaryPath = Path(iseSection['BinaryDirectory'])
		version = iseSection['Version']
		self._toolChain = ISE(self.Host.Platform, binaryPath, version, logger=self.Logger)

	def RunAll(self, fqnList, *args, **kwargs):
		for fqn in fqnList:
			entity = fqn.Entity
			if (isinstance(entity, WildCard)):
				for netlist in entity.GetCoreGenNetlists():
					self.TryRun(netlist, *args, **kwargs)
			else:
				netlist = entity.CGNetlist
				self.TryRun(netlist, *args, **kwargs)

	def Run(self, netlist, board):
		super().Run(netlist, board)

		self._LogNormal("Executing pre-processing tasks...")
		self._RunPreCopy(netlist)
		self._RunPreReplace(netlist)

		self._LogNormal("Running Xilinx Core Generator...")
		self._RunCompile(netlist, board.Device)

		self._LogNormal("Executing post-processing tasks...")
		self._RunPostCopy(netlist)
		self._RunPostReplace(netlist)
		self._RunPostDelete(netlist)

	def _WriteSpecialSectionIntoConfig(self, device):
		# add the key Device to section SPECIAL at runtime to change interpolation results
		self.Host.PoCConfig['SPECIAL'] = {}
		self.Host.PoCConfig['SPECIAL']['Device'] =        device.FullName
		self.Host.PoCConfig['SPECIAL']['DeviceSeries'] =  device.Series
		self.Host.PoCConfig['SPECIAL']['OutputDir']	=      self.Directories.Working.as_posix()

	def _RunCompile(self, netlist, device):
		self._LogVerbose("Patching coregen.cgp and .cgc files...")
		# read netlist settings from configuration file
		xcoInputFilePath =    netlist.XcoFile
		cgcTemplateFilePath =  self.Directories.Netlist / "template.cgc"
		cgpFilePath =          self.Directories.Working / "coregen.cgp"
		cgcFilePath =          self.Directories.Working / "coregen.cgc"
		xcoFilePath =          self.Directories.Working / xcoInputFilePath.name

		if (self.Host.Platform == "Windows"):
			WorkingDirectory = ".\\temp\\"
		else:
			WorkingDirectory = "./temp/"

		# write CoreGenerator project file
		cgProjectFileContent = dedent("""\
			SET addpads = false
			SET asysymbol = false
			SET busformat = BusFormatAngleBracketNotRipped
			SET createndf = false
			SET designentry = VHDL
			SET device = {Device}
			SET devicefamily = {DeviceFamily}
			SET flowvendor = Other
			SET formalverification = false
			SET foundationsym = false
			SET implementationfiletype = Ngc
			SET package = {Package}
			SET removerpms = false
			SET simulationfiles = Behavioral
			SET speedgrade = {SpeedGrade}
			SET verilogsim = false
			SET vhdlsim = true
			SET workingdirectory = {WorkingDirectory}
			""".format(
			Device=device.ShortName.lower(),
			DeviceFamily=device.FamilyName.lower(),
			Package=(str(device.Package).lower() + str(device.PinCount)),
			SpeedGrade=device.SpeedGrade,
			WorkingDirectory=WorkingDirectory
		))

		self._LogDebug("Writing CoreGen project file to '{0}'.".format(cgpFilePath))
		with cgpFilePath.open('w') as cgpFileHandle:
			cgpFileHandle.write(cgProjectFileContent)

		# write CoreGenerator content? file
		self._LogDebug("Reading CoreGen content file to '{0}'.".format(cgcTemplateFilePath))
		with cgcTemplateFilePath.open('r') as cgcFileHandle:
			cgContentFileContent = cgcFileHandle.read()

		cgContentFileContent = cgContentFileContent.format(
			name="lcd_ChipScopeVIO",
			device=device.ShortName,
			devicefamily=device.FamilyName,
			package=(str(device.Package) + str(device.PinCount)),
			speedgrade=device.SpeedGrade
		)

		self._LogDebug("Writing CoreGen content file to '{0}'.".format(cgcFilePath))
		with cgcFilePath.open('w') as cgcFileHandle:
			cgcFileHandle.write(cgContentFileContent)

		# copy xco file into temporary directory
		self._LogVerbose("Copy CoreGen xco file to '{0}'.".format(xcoFilePath))
		self._LogDebug("cp {0!s} {1!s}".format(xcoInputFilePath, self.Directories.Working))
		shutil.copy(str(xcoInputFilePath), str(xcoFilePath), follow_symlinks=True)

		# change working directory to temporary CoreGen path
		self._LogDebug("cd {0!s}".format(self.Directories.Working))
		chdir(str(self.Directories.Working))

		# running CoreGen
		# ==========================================================================
		self._LogVerbose("Executing CoreGen...")
		coreGen = self._toolChain.GetCoreGenerator()
		coreGen.Parameters[coreGen.SwitchProjectFile] =  "."		# use current directory and the default project name
		coreGen.Parameters[coreGen.SwitchBatchFile] =    str(xcoFilePath)
		coreGen.Parameters[coreGen.FlagRegenerate] =    True

		try:
			coreGen.Generate()
		except ISEException as ex:
			raise CompilerException("Error while compiling '{0!s}'.".format(netlist)) from ex
		if coreGen.HasErrors:
			raise SkipableCompilerException("Error while compiling '{0!s}'.".format(netlist))

