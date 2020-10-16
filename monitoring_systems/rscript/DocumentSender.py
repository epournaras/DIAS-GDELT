import telegram
from telegram.ext import Updater, CommandHandler
from wand.image import Image
from subprocess import Popen
import subprocess
from datetime import datetime, timedelta
from threading import Timer
import urllib
import tempfile
import pexpect
import traceback

import configparser
import os, sys

parser = configparser.ConfigParser()
path = os.path.dirname(sys.argv[0])
if not path:
    path = '.'
parser.read(path + "/" + "config.conf")

TELEGRAM_TOKEN = parser["Telegram"]["telegram_token"]
CHAT_ID = parser["Telegram"]["chat_id"]

REMOTE_HOST_USERNAME = parser["Remote"]["ssh_username"]
REMOTE_HOST_PASSWORD = parser["Remote"]["ssh_password"]

HOST = parser["Remote"]["ip"] #Remote host, can be local
COMMAND = "df -h" #Command to check system space

MONITORINGTIME = {'HOUR': int(parser["Monitoring"]["hour"]), 'MINUTE': int(parser["Monitoring"]["minute"]), 'SECOND': int(parser["Monitoring"]["second"]), 'MICROSECOND': int(parser["Monitoring"]["microsecond"])}
INTERVALINDAYS = int(parser["Monitoring"]["interval_in_days"])

RUN_C0 = bool(parser["Servers"]["run_c0"])
RUN_C1 = bool(parser["Servers"]["run_c1"])



mybot = telegram.Bot(token=TELEGRAM_TOKEN)



def runDayly():
    try:
        print("firing daily execution")
        mybot.sendMessage(chat_id=CHAT_ID, text="Good Morning! Here is the newest plot from the server, is everything going well?")
        plot_and_sendC0()
        plot_and_sendC1()
        schedule()
    except Exception as e:
        mybot.sendMessage(chat_id=CHAT_ID, text="An Error occured: {}".format(traceback.format_exc()))

def convertPdfToPhoto(directory):
        try:
            f = directory + 'Rplots.pdf'
            with(Image(filename=f, resolution=240)) as source:
                Image(source.convert('jpg')).save(filename= directory + 'Rplots.jpg')
        except Exception as e:
            print(e)

def sendNewestPdf(msg, directory, chatid, bot=mybot):
    with open( directory + 'Rplots.pdf', 'rb') as f:
        bot.sendDocument(chat_id = chatid, document=f, caption=msg)

def sendNewestPhoto(msg, directory, chatid, bot=mybot):
    with open(directory + 'Rplots.jpg', 'rb') as f:
        bot.sendPhoto(chat_id = chatid, photo=f, caption=msg)

def sendMessage(msg, chatid, bot=mybot):
    bot.sendMessage(chat_id=chatid, text=msg, parse_mode="Markdown")

def plot_and_sendC0(chatid=CHAT_ID):
    if not RUN_C0:
        return

    print("starting plotting C0...")
    directory = 'C0/'
    p = Popen(['/usr/bin/Rscript','--vanilla', directory + 'read.and.plot.aggregates.and.true.C0.R'])
    p.wait()
    print("finished plotting")

    print("converting pdf to photo")
    convertPdfToPhoto(directory)
    print("end converting")
    try:
        print("sending data to " + str(chatid))
    except Exception as e:
        print(e)
        raise e
    sendNewestPdf('C0', directory, chatid)
    sendNewestPhoto('C0', directory, chatid)
    s, w = getUsageC0()
    sendMessage(s, chatid)
    if w != '':
        for ln in w.split("\n")[:-1]:
            sendMessage(ln, chatid)

def getUsageC0():
    df = subprocess.Popen(["df", "-h"], stdout=subprocess.PIPE)
    output = df.communicate()

    s = ""
    w = ""
    lines = output[0].decode().split("\n")

    s += lines[0] + '\n'

    for line in lines[1:(lines.__len__()-1)]:
        max = 80
        perc = int(line.split()[4][:-1])
        env = line.split()[0]
        if(perc >= max):
            w += ("`WARNING:: more than {}% ({}%): {}`\n".format(max, perc, env))
        s += line + '\n'
    return s, w

def plot_and_sendC1(chatid=CHAT_ID):
    if HOST == "":
        return
    if not RUN_C1:
        return
    def sendMessageC1(msg, bot=mybot):
        bot.sendMessage(chat_id=chatid, text=msg)
    print("starting plotting C1 avg...")
    directory = 'C1/'
    p = Popen(['/usr/bin/Rscript','--vanilla', directory + 'read.and.plot.aggregates.and.true.C1.avg.R'])
    p.wait()
    print("finished plotting")

    print("converting pdf to photo")
    convertPdfToPhoto(directory)

    print("sending data to " + str(chatid))
    sendNewestPdf('C1 average', directory, chatid)
    sendNewestPhoto('C1 average', directory, chatid)

    print("starting plotting C1 count...")
    p = Popen(['/usr/bin/Rscript','--vanilla', directory + 'read.and.plot.aggregates.and.true.C1.count.R'])
    p.wait()
    print("finished plotting")


    print("converting pdf to photo")
    convertPdfToPhoto(directory)

    print("sending data to " + str(chatid))
    sendNewestPdf('C1 count', directory, chatid)
    sendNewestPhoto('C1 count', directory, chatid)
    s, w = getUsageC1()
    sendMessageC1(s)
    if w != '':
        for ln in w.split("\n")[:-1]:
            sendMessageC1(ln)

def ssh(timeout=30, bg_run=False):
    host = HOST
    cmd = COMMAND
    user = REMOTE_HOST_USERNAME #postgres username
    password = REMOTE_HOST_PASSWORD #postgres password
    fname = tempfile.mktemp()
    fout = open(fname, 'wb')

    options = '-q -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oPubkeyAuthentication=no'
    if bg_run:
        options += ' -f'
    ssh_cmd = 'ssh %s@%s %s "%s"' % (user, host, options, cmd)
    child = pexpect.spawn(ssh_cmd, timeout=timeout)
    child.expect(['password: '])
    child.sendline(password)
    child.logfile = fout
    child.expect(pexpect.EOF)
    child.close()
    fout.close()
    fin = open(fname, 'r')
    stdout = fin.read()
    fin.close()

    return stdout

def getUsageC1():
    df = ssh()
    lines = df.split("\n")
    s = ''
    w = ""
    s += lines[1] + '\n'

    for line in lines[2:(lines.__len__()-1)]:
        max = 80
        perc = int(line.split()[4][:-1])
        env = line.split()[0]
        if(perc >= max):
            w += ("`WARNING:: more than {}%: {}`\n".format(max, env))
        s += line + '\n'
    return s, w

def command_plotC0(bot, update):
    print("/plot for C0 requested from " + update.message.from_user.first_name)
    bot.send_message(chat_id=update.message.chat_id, text="one freshly made plot for C0 coming right up!")
    plot_and_sendC0(update.message.chat_id)

def command_plotC1(bot, update):
    print("/plot for C1 requested from " + update.message.from_user.first_name)
    bot.send_message(chat_id=update.message.chat_id, text="one freshly made plot for C1 coming right up!")
    plot_and_sendC1(update.message.chat_id)

def schedule():
    x = datetime.today()
    y = x.replace(day=x.day, hour=MONITORINGTIME['HOUR'], minute=MONITORINGTIME['MINUTE'], second=MONITORINGTIME['SECOND'], microsecond=MONITORINGTIME['MICROSECOND']) + timedelta(days=INTERVALINDAYS)
    print("scheduled for " + str(y))
    delta_t=y-x
    secs=delta_t.seconds+1
    t = Timer(secs, runDayly)
    t.start()

runDayly()

updater = Updater(TELEGRAM_TOKEN)
dp = updater.dispatcher
dp.add_handler(CommandHandler('plotc0', command_plotC0))
dp.add_handler(CommandHandler('plotc1', command_plotC1))
updater.start_polling()
print("started")
updater.idle()



