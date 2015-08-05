# logzio-rsyslog 1.0.0

Configure rsyslog to send verity of system log to Logz.io
Contains an intuitive and easy to use installation setup the will enable you to monitor your local system logs and/or any of the running demon log files, and ship them over to Logz.io.  

## requirements
 - The setup assumes that you have a sudo access
 - Rsyslog version 5.8.0 and above
 - Allow outgoing TCP traffic to destination port 5000
 - A common linux distribution
 - A valid Logz.io customer authentication token 

## Install:
```bash
curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
tar xzf logzio-rsyslog.tar.gz
```

## Usage:

```bash
sudo rsyslog/install.sh -t TYPE -a TOKEN
```

#### The script include the following use cases: 
- Local system logs files monitoring
- Application logs files monitoring

#### Script options:

** -t | --type ** Alowed values:
-  linux
	
	Local system logs files monitoring


 
### Local system logs:

Configure rsyslog to monitor logs from vireos system facilities on your local system (kernel, user-level messages, system daemons, security/authorization messages, etc.) and ship them to over Logz.io.

In the following sample please replace:
 - TOKEN, with your customer authentication token.

```bash
curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
tar xzf logzio-rsyslog.tar.gz
sudo rsyslog/install.sh -t linux -a "TOKEN"
```

### Application specific log file:

Configure rsyslog to monitor logs from a specific application syslog daemon, and ship them to over Logz.io. 
Currently support for Apache2 and Nginx, access and error logs.

In the following sample please replace:
 - TOKEN, with your customer authentication token.

Monitor Apache syslog:

```bash
curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
tar xzf logzio-rsyslog.tar.gz
sudo rsyslog/install.sh -t apache -a "TOKEN"
```

Monitor Nginx syslog:

```bash
curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
tar xzf logzio-rsyslog.tar.gz
sudo rsyslog/install.sh -t nginx -a "TOKEN"
```

### A General Linux log file:

Configure rsyslog to monitor logs from general a syslog daemon. It can monitor a single log file or a directory, and ship them to over Logz.io.
In case of directory all first level files will be monitored.

In the following sample please replace:
 - TOKEN, with your customer authentication token.
 - FILE, /path/to/file/or/directory
 - APP_NAME, The application witch those log belong to.

```bash
curl -sLO https://github.com/logzio/logzio-shipper/raw/master/dist/logzio-rsyslog.tar.gz
tar xzf logzio-rsyslog.tar.gz
sudo rsyslog/install.sh -t file -a "TOKEN" -f "FILE" --tag "APP_NAME"
```



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
