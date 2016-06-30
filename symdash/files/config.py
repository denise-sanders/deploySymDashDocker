import src.base_config
import os
__author__ = 'matt8057'

BASE_DIR = 'omitted'

class DevelopmentConfig(src.base_config.Config):
    DEBUG = True
    ADMINS = frozenset(['matthew.alline@RACKSPACE.com'])
    DASHBOARD_PORT = 8008

    LOGS_DIR = os.path.join(os.path.abspath(os.path.join(BASE_DIR, os.pardir)), 'logs')

    MAAS_USER = 'cloudnw2'
    MAAS_API_KEY = 'omitted'
    MAAS_TENANT = 'omitted'

    IDENTITY_URL = 'https://identity.api.rackspacecloud.com/v2.0/tokens'
    POSTGRES_CONNECTIONS = {
        'symetric': {
            'dbname': 'symetric',
            'user': 'postgres',
            'host': '10.66.8.58',
            'port': '5432',
            'password': 'omitted'
        }
    }

    MONGO_CONNECTIONS = {
        'symetric': {
            'host': 'localhost',
            'port': '27017',
            'dbame': 'symetric',
            'user': 'symetric',
            'password': 'omitted'
        }
    }

