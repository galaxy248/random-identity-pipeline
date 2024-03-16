import logging
import pathlib


root_path = pathlib.Path(__file__).parent.parent


class Log():
    def __init__(self) -> None:
        error_FH_formatter = logging.Formatter(fmt="%(asctime)s - %(levelname)s: %(message)s", datefmt="%Y-%m-%d %H:%M:%S")
        error_CH_formatter = logging.Formatter(fmt="%(levelname)s: %(message)s")
        self.error_logger: logging.Logger = logging.getLogger('log the program errors.')
        self.error_logger.setLevel(logging.WARNING)
        error_file_handler = logging.FileHandler(root_path / "log/error.log")
        error_file_handler.setFormatter(error_FH_formatter)
        error_console_handler = logging.StreamHandler()
        error_console_handler.setFormatter(error_CH_formatter)
        self.error_logger.addHandler(error_file_handler)
        self.error_logger.addHandler(error_console_handler)
        
        info_FH_formatter = logging.Formatter(fmt="%(asctime)s: %(message)s", datefmt="%Y-%m-%d %H:%M:%S")
        info_CH_formatter = logging.Formatter(fmt="%(message)s")
        self.info_logger: logging.Logger = logging.getLogger('log the program info messages.')
        self.info_logger.setLevel(logging.INFO)
        info_file_handler = logging.FileHandler(root_path / "log/info.log")
        info_file_handler.setFormatter(info_FH_formatter)
        info_console_handler = logging.StreamHandler()
        info_console_handler.setFormatter(info_CH_formatter)
        self.info_logger.addHandler(info_file_handler)
        self.info_logger.addHandler(info_console_handler)
    
    def error(self, msg: str) -> None:
        self.error_logger.error(msg)
    
    def warning(self, msg: str) -> None:
        self.error_logger.warning(msg)
    
    def critical(self, msg: str) -> None:
        self.error_logger.critical(msg)
    
    def info(self, msg: str) -> None:
        self.info_logger.info(msg)

if __name__ == '__main__':
    logger = Log()
    logger.error('Test error')
    logger.warning('Test warning')
    logger.critical('Test critical')
    logger.info('Test info')
