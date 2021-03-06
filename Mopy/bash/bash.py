# -*- coding: utf-8 -*-
#
# GPL License and Copyright Notice ============================================
#  This file is part of Wrye Flash.
#
#  Wrye Flash is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  Wrye Flash is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Wrye Flash; if not, write to the Free Software Foundation,
#  Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#  Wrye Flash copyright (C) 2005, 2006, 2007, 2008, 2009 Wrye
#
# =============================================================================

"""This module starts the Wrye Flash application in console mode. Basically, it runs some
initialization functions and then starts the main application loop."""

# Imports ---------------------------------------------------------------------
import atexit
import os
from time import time, sleep
import sys

if sys.version[:3] == '2.4':
    import wxversion

    wxversion.select("2.5.3.1")
import optparse
import re

import bolt
from bolt import _, GPath

basherImported = False


# ----------------------------------------------------------------------------------
def SetHomePath(homePath):
    drive, path = os.path.splitdrive(homePath)
    os.environ['HOMEDRIVE'] = drive
    os.environ['HOMEPATH'] = path


# ----------------------------------------------------------------------------------
def GetBashIni(iniPath):
    import ConfigParser
    bashIni = None
    if os.path.exists(iniPath):
        bashIni = ConfigParser.ConfigParser()
        bashIni.read(iniPath)
    return bashIni


# ----------------------------------------------------------------------------------
def SetUserPath(iniPath, uArg=None):
    # if uArg is None, then get the UserPath from the ini file
    if uArg:
        SetHomePath(uArg)
    elif os.path.exists(iniPath):
        bashIni = GetBashIni(iniPath)
        if bashIni and bashIni.has_option('General',
            'sUserPath') and not bashIni.get('General', 'sUserPath') == '.':
            SetHomePath(bashIni.get('General', 'sUserPath'))


# Backup/Restore --------------------------------------------------------------
def cmdBackup():
    # backup settings if app version has changed or on user request
    if not basherImported:
        import basher, barb
    backup = None
    path = None
    quit = opts.backup and opts.quietquit
    if opts.backup: path = GPath(opts.filename)
    backup = barb.BackupSettings(basher.bashFrame, path, quit,
        opts.backup_images)
    if backup.PromptMismatch() or opts.backup:
        try:
            backup.Apply()
        except bolt.StateError:
            if backup.SameAppVersion():
                backup.WarnFailed()
            elif backup.PromptQuit():
                return False
        except barb.BackupCancelled:
            if not backup.SameAppVersion() and not backup.PromptContinue():
                return False
    del backup
    return not quit


def cmdRestore():
    # restore settings on user request
    if not basherImported: import basher, barb
    backup = None
    path = None
    quit = opts.restore and opts.quietquit
    if opts.restore: path = GPath(opts.filename)
    if opts.restore:
        try:
            backup = barb.RestoreSettings(basher.bashFrame, path, quit,
                opts.backup_images)
            backup.Apply()
        except barb.BackupCancelled:
            pass
    del backup
    return not quit


# -----------------------------------------------------------------------------
# adapted from: http://www.effbot.org/librarybook/msvcrt-example-3.py
def oneInstanceChecker():
    global pidpath, lockfd
    pidpath = bolt.Path.getcwd().root.join('pidfile.tmp')
    lockfd = None

    if opts.restarting:  # wait up to 10 seconds for previous instance to close
        t = time()
        while (time() - t < 10) and pidpath.exists(): sleep(1)

    try:
        # if a stale pidfile exists, remove it (this will fail if the file is currently locked)
        if pidpath.exists(): os.remove(pidpath.s)
        lockfd = os.open(pidpath.s, os.O_CREAT | os.O_EXCL | os.O_RDWR)
        os.write(lockfd, "%d" % os.getpid())
    except OSError, e:
        # lock file exists and is currently locked by another process
        print 'already started'
        return False

    return True


def exit():
    try:
        os.close(lockfd)
        os.remove(pidpath.s)
    except OSError, e:
        print e

    try:
        # Cleanup temp installers directory
        import bosh
        bosh.Installer.tempDir.rmtree(bosh.Installer.tempDir.stail)
    except:
        pass

    # TODO: Why is basher.appRestart here?
    if basherImported and basher.appRestart:
        exePath = GPath(sys.executable)
        sys.argv = [exePath.stail] + sys.argv + ['--restarting']
        sys.argv = ['\"' + x + '\"' for x in
                    sys.argv]  # quote all args in sys.argv
        try:
            import subprocess
            subprocess.Popen(sys.argv, executable = exePath.s,
                close_fds = bolt.close_fds)  # close_fds is needed for the one instance checker
        except Exception, error:
            print error
            print _("Error Attempting to Restart Wrye Flash!")
            print _("cmd line: "), exePath.s, sys.argv
            print
            raise


# Main ------------------------------------------------------------------------
def main():
    global opts, extra

    parser = optparse.OptionParser()
    pathGroup = optparse.OptionGroup(parser, "Path Arguments",
        r"All path arguments must be absolute paths and use either forward slashes (/) or two backward slashes (\\). All of these can also be set in the ini (where  you can also use relative paths) and if set in both cmd line takes precedence.")
    pathGroup.add_option('-o', '--falloutPath', action = 'store',
        type = 'string', default = '', dest = 'falloutPath',
        help = 'Specifies the Fallout3 directory (the one containing Fallout3.exe). Use this argument if Bash is located outside of the Fallout3 directory.')
    userPathGroup = optparse.OptionGroup(parser, "'User Directory Arguments",
        'These arguments allow you to specify your user directories in several ways.'
        ' These are only useful if the regular procedure for getting the user directory fails.'
        ' And even in that case, the user is probably better off installing win32com.')
    userPathGroup.add_option('-p', '--personalPath', action = 'store',
        type = 'string', default = '', dest = 'personalPath',
        help = 'Specify the user\'s personal directory. (Like "C:\\\\Documents and Settings\\\\Wrye\\\\My Documents\") '
               'If you need to set this then you probably need to set -l too')
    userPathGroup.add_option('-u', '--userPath', action = 'store',
        type = 'string', default = '', dest = 'userPath',
        help = 'Specify the user profile path. May help if HOMEDRIVE and/or HOMEPATH'
               ' are missing from the user\'s environment')
    userPathGroup.add_option('-l', '--localAppDataPath', action = 'store',
        type = 'string', default = '', dest = 'localAppDataPath',
        help = 'Specify the user\'s local application data directory.'
               'If you need to set this then you probably need to set -p too.')
    backupGroup = optparse.OptionGroup(parser, "'Backup and Restore Arguments",
        'These arguments allow you to do backup and restore settings operations.')
    backupGroup.add_option('-b', '--backup', action = 'store_true',
        default = False, dest = 'backup',
        help = 'Backup all Bash settings to an archive file before the app launches. Either specify the filepath with  the -f/--filename options or Wrye Flash will prompt the user for the backup file path.')
    backupGroup.add_option('-r', '--restore', action = 'store_true',
        default = False, dest = 'restore',
        help = 'Backup all Bash settings to an archive file before the app launches. Either specify the filepath with  the -f/--filename options or Wrye Flash will prompt the user for the backup file path.')
    backupGroup.add_option('-f', '--filename', action = 'store', default = '',
        dest = 'filename',
        help = 'The file to use with the -r or -b options. Must end in \'.7z\' and be a valid path and for -r exist and for -b not already exist.')
    backupGroup.add_option('-q', '--quiet-quit', action = 'store_true',
        default = False, dest = 'quietquit',
        help = 'Close Bash after creating or restoring backup and do not display any prompts or message dialogs.')
    parser.set_defaults(backup_images = 0)
    backupGroup.add_option('-i', '--include-changed-images',
        action = 'store_const', const = 1, dest = 'backup_images',
        help = 'Include changed images from mopy/bash/images in the backup. Include any image(s) from backup file in restore.')
    backupGroup.add_option('-I', '--include-all-images', action = 'store_const',
        const = 2, dest = 'backup_images',
        help = 'Include all images from mopy/bash/images in the backup/restore (if present in backup file).')
    parser.add_option('-d', '--debug', action = 'store_true', default = False,
        dest = 'debug',
        help = 'Useful if bash is crashing on startup or if you want to print a lot of '
               'information (e.g. while developing or debugging).')
    parser.add_option('--no-psyco', action = 'store_false', default = True,
        dest = 'Psyco', help = 'Disables import of Psyco')
    parser.set_defaults(mode = 0)
    parser.add_option('-C', '--Cbash-mode', action = 'store_const', const = 2,
        dest = 'mode',
        help = 'enables CBash and uses CBash to build bashed patch.')
    parser.add_option('-P', '--Python-mode', action = 'store_const', const = 1,
        dest = 'mode',
        help = 'disables CBash and uses python code to build bashed patch.')
    parser.set_defaults(unicode = '')
    parser.add_option('-U', '--Unicode', action = 'store_true',
        dest = 'unicode',
        help = 'enables Unicode mode, overriding the ini if it exists.')
    parser.add_option('-A', '--Ansi', action = 'store_false', dest = 'unicode',
        help = 'disables Unicode mode, overriding the ini if it exists.')
    parser.add_option('--restarting', action = 'store_true', default = False,
        dest = 'restarting', help = optparse.SUPPRESS_HELP)
    parser.add_option('--genHtml', default = None,
        help = optparse.SUPPRESS_HELP)

    parser.add_option_group(pathGroup)
    parser.add_option_group(userPathGroup)
    parser.add_option_group(backupGroup)

    opts, extra = parser.parse_args()
    if len(extra) > 0:
        parser.print_help()
        return

    bolt.deprintOn = opts.debug

    if opts.Psyco:
        try:
            import psyco
            psyco.full()
        except:
            pass
    if opts.unicode != '':
        bolt.bUseUnicode = int(opts.unicode)
    # --Initialize Directories and some settings
    #  required before the rest has imported
    SetUserPath('bash.ini', opts.userPath)

    try:
        bolt.CBash = opts.mode
        import bosh
        bosh.initBosh(opts.personalPath, opts.localAppDataPath,
            opts.falloutPath)
        bosh.exe7z = bosh.dirs['compiled'].join(bosh.exe7z).s

        # if HTML file generation was requested, just do it and quit
        if opts.genHtml is not None:
            print "generating HTML file from: '%s'" % opts.genHtml
            import belt
            bolt.WryeText.genHtml(opts.genHtml)
            print "done"
            return

        import basher
        import barb
        import balt
    except bolt.PermissionError, e:
        if opts.debug:
            if hasattr(sys, 'frozen'):
                app = basher.BashApp()
            else:
                app = basher.BashApp(False)
            bolt.deprintOn = True
        else:
            app = basher.BashApp()
        balt.showError(None, str(e))
        app.MainLoop()
        raise

    if not oneInstanceChecker(): return
    # Alternative one instance scheme
    ##    try:
    ##        import socket
    ##        s = socket.socket()
    ##        host = socket.gethostname()
    ##        port = 35636    #make sure this port is not used on this system
    ##        s.bind((host, port))
    ##    except:
    ##        print 'already started'
    ##        return
    atexit.register(exit)
    basher.InitSettings()
    basher.InitLinks()
    basher.InitImages()
    # --Start application
    if opts.debug:
        if hasattr(sys, 'frozen'):
            # Special case for py2exe version
            app = basher.BashApp()
        else:
            app = basher.BashApp(False)
    else:
        app = basher.BashApp()

    if sys.version[
       0:3] < '2.6':  # nasty, may cause failure in oneInstanceChecker but better than bash failing to open things for no (user) apparent reason such as in 2.5.2 and under.
        bolt.close_fds = False
        if sys.version[0:3] == 2.5:
            run = balt.askYes(None,
                "Warning: You are using a python version prior to 2.6 and there may be some instances that failures will occur. Updating is recommended but not imperative. Do you still want to run Wrye Flash right now?",
                "Warning OLD Python version detected")
        else:
            run = balt.askYes(None,
                "Warning: You are using a Python version prior to 2.5x which is totally out of date and ancient and Bash will likely not like it and may totally refuse to work. Please update to a more recent version of Python(2.6x or 2.7x is preferred). Do you still want to run Wrye Flash?",
                "Warning OLD Python version detected")
        if not run:
            return

    # process backup/restore options
    quit = False  # quit if either is true, but only after calling both
    quit = quit or not cmdBackup()
    quit = quit or not cmdRestore()
    if quit: return

    app.Init()
    # Testing code to see if a spawned process is blocking the one instance checker from working
    ##    try:
    app.MainLoop()


##    finally:
##        s.close()
##        b = socket.socket()
##        try:
##            b.bind((host, port))
##        except:
##            print "Unable to rebind supposedly closed port!"
##        print "Really exitted"

if __name__ == '__main__':
    main()
