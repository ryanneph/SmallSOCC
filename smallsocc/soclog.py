import os
import logging
import logging.config
import json

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
