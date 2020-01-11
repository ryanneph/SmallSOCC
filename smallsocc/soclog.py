import os
import logging
import logging.config
import json

# custom logging levels
logging.DEBUG2 = 5
logging.MONITOR = 9

logging.addLevelName(logging.DEBUG2, "DEBUG2")
def debug2(self, message, *args, **kws):
    # Yes, logger takes its '*args' as 'args'.
    if self.isEnabledFor(logging.DEBUG2):
        self._log(logging.DEBUG2, message, args, **kws)
logging.Logger.debug2 = debug2

logging.addLevelName(logging.MONITOR, "MONITOR")
def monitor(self, message, *args, **kws):
    # Yes, logger takes its '*args' as 'args'.
    if self.isEnabledFor(logging.MONITOR):
        self._log(logging.MONITOR, message, args, **kws)
logging.Logger.monitor = monitor

def init_logging(level=None, config_path='logging.conf.json'):
    """Setup logging configuration"""
    path = os.getenv('LOG_CFG', None)
    if path:
        config_path = path
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            config = json.load(f)
            config["disable_existing_loggers"] = False
        logging.config.dictConfig(config)

        # init log level on primary loggers
        if level:
            for logger in ['', 'qml']:
                logging.getLogger(logger).setLevel(level)
    else:
        logging.basicConfig(level=level)

class NoQMLFilter():
    def __call__(self, record):
        return self.filter(record)

    def filter(self, record: logging.LogRecord):
        if 'qml' in record.name:
            return False
        else: return True
