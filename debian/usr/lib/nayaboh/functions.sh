#!/bin/bash -e

# Copyright 2010 Boris Daeppen <boris_daeppen@bluewin.ch>
# 
# This file is part of NaYaBoh.
# 
# NaYaBoh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# NaYaBoh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with NaYaBoh.  If not, see <http://www.gnu.org/licenses/>.

function restart_dnsmasq {
    echo 'restart dnsmasq'
    # should try invoke-rc.d, like told here:
    # http://www.debian.org/doc/debian-policy/ch-opersys.html#s9.3.3.2
    if which invoke-rc.d >/dev/null 2>&1; then
        sudo invoke-rc.d dnsmasq restart
    else
        sudo /etc/init.d/dnsmasq restart
    fi
}

function stop_dnsmasq {
    if which invoke-rc.d >/dev/null 2>&1; then
        sudo invoke-rc.d dnsmasq stop
    else
        sudo /etc/init.d/dnsmasq stop
    fi
}


function restart_squid {
    echo 'restart squid'
    # because ubuntu 10.04 is using upstart for squid
    # but debian does not I need to find out which system is used
    if which initctl && initctl --version | grep -i upstart
        then
        echo 'upstart installed, try use upstart...'
        echo 'stopping squid...'
        # use Upstart-Stop only if squid is up!
        if ps aux | grep squid | grep -v grep
            then
            sudo service squid stop
            # then wait and check if squid is finally down
            sleep 5
            while ps aux | grep squid | grep -v grep
            do
                echo 'squid is still up, waiting 3 seconds...'
                sleep 3
            done
        fi
        echo 'squid is down!'
        # I hate and/or don't understand Upstart...
        sleep 1
        echo 'starting squid...'
        # ...at least starting is easy
        sudo service squid start
    else
        echo 'no upstart installed, try use init script...'
        # should try invoke-rc.d, like told here:
        # http://www.debian.org/doc/debian-policy/ch-opersys.html#s9.3.3.2
        if which invoke-rc.d >/dev/null 2>&1; then
            sudo invoke-rc.d squid restart
        else
            sudo /etc/init.d/squid restart
        fi
    fi
}

