# logzio-rsyslog

Configure rsyslog to send verity of system log to [Logz.io](https://logz.io).
Contains an intuitive and easy to use installation setup the will enable you to monitor your local system logs and/or any of the running daemon log files, and ship them over to [Logz.io](https://logz.io).  

## Requirements
 - The setup assumes that you have a sudo access
 - Rsyslog version 5.8.0 and above
 - Allow outgoing TCP traffic to destination port 5000
 - A common linux distribution
 - A valid Logz.io customer authentication token, which can be obtained with an account on [Logz.io's website](https://logz.io)

## Install:
```bash
curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz ; tar xzf logzio-rsyslog.tar.gz
```

## Usage:

```bash
sudo rsyslog/install.sh -t TYPE -a TOKEN [--quite] [--filepath] [--filetag] [--accesslog] [--errorlog] 
```

#### Script options:

**-a | --authtoken** 
	
	Logz.io customer authentication token.

**-t | --type** 
	
	Alowed values:
	-  linux
	
	Local system logs files monitoring:
	Configure rsyslog to monitor logs from vireos system facilities on your local system (kernel, user-level messages, system daemons, security/authorization messages, etc.) and ship them over to [Logz.io](https://logz.io).

	- file

	A General log file:
	Configure rsyslog to monitor a log file. It can monitor a single log file or a directory, and ship them over to [Logz.io](https://logz.io).

	- apache

	Apache log files:
	Configure rsyslog to monitor Apache2 access and error log files, and ship them over to [Logz.io](https://logz.io)
	The script will attempt to resolve the location of the log files according to the OS distribution.
	For yum based distributions the log file will be mapped to:
	- access `/var/log/httpd/access_log` (can be overrided using the option --accesslog)
	- error `/var/log/httpd/error_log` (can be overrided using the option --errorlog)
	For apt based distributions the log file will be mapped to:
	- access `/var/log/apache2/access.log` (can be overrided using the option --accesslog)
	- error `/var/log/apache2/error.log` (can be overrided using the option --errorlog)

	- nginx

	Nginx log files:
	Configure rsyslog to monitor Nginx access and error log files, and ship them over to Logz.io
	The script will attempt to resolve the location of the log files.
	- access `/var/log/nginx/access.log` (can be overrided using the option --accesslog)
	- error `/var/log/nginx/error.log` (can be overrided using the option --errorlog)

**-q | --quite** 

	Interactive mode mode is disabled (enabled by default).

#### Extended Script options:

The following option avilable only when using the `--type file` option

**-p | --filepath** 

	Sets the monitored file type.

**-tag| --filetag** 
	
	Attach a TAG value to a monitored file.


### Example and use cases:

The script include the following use cases: 
- Local system logs files monitoring
- Application logs files monitoring

#### Local system logs:

Configure rsyslog to monitor logs from various system facilities on your local system (kernel, user-level messages, system daemons, security/authorization messages, etc.) and ship them over to Logz.io.

In the following sample please replace:
 - TOKEN, with your customer authentication token.

```bash
curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
tar xzf logzio-rsyslog.tar.gz
sudo rsyslog/install.sh -t linux -a "TOKEN"
```

#### An Apache/Nginx log file:

Configure rsyslog to monitor access and error log files, and ship them over to Logz.io. 
Currently support for Apache2 and Nginx, access and error logs.

In the following sample please replace:
 - TOKEN, with your customer authentication token.
 - accesslog and errorlog are optional

Monitor Apache syslog:

```bash
curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
tar xzf logzio-rsyslog.tar.gz
sudo rsyslog/install.sh -t apache -a "TOKEN" [--accesslog] [--errorlog]
```

Monitor Nginx syslog:

```bash
curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
tar xzf logzio-rsyslog.tar.gz
sudo rsyslog/install.sh -t nginx -a "TOKEN" [--accesslog] [--errorlog] 
```

#### A General Linux log file:

	Configure rsyslog to monitor Apache2 access and error log files, and ship them over to [Logz.io](https://logz.io)
Configure rsyslog to monitor a log. It can monitor a single log file or a directory, and ship them over to Logz.io.
In case of directory all first level files will be monitored.

In the following sample please replace:
 - TOKEN, with your customer authentication token.
 - FILE, /path/to/file/or/directory
 - APP_NAME, The application witch those logs belong to.

```bash
curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
tar xzf logzio-rsyslog.tar.gz
sudo rsyslog/install.sh -t file -a "TOKEN" -f "FILE" --tag "APP_NAME" [--filepath] [--filetag] 
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
