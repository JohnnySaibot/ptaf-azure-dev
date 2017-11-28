#!/opt/waf/python/bin/python

import json  # to avoid bug in requests lib
import requests


AUTH_HEADER = {'Authorization': 'Basic YXBpYzpwMHMxdDF2Mw=='}
API_ROOT = 'https://localhost:8443/api/waf/v2/'


def endpoint(name):
    return API_ROOT + name


def create_alias(name, alias_type):
    return json.loads(
        requests.post(
            endpoint('interface_aliases'),
            headers=AUTH_HEADER,
            json={'name': name, 'type': alias_type},
            verify=False
        ).content
    )


def alias_by_name(name):
    return next(
        alias['id'] for alias in json.loads(
            requests.get(
                endpoint('interface_aliases'),
                headers=AUTH_HEADER,
                verify=False
            ).content
        )['items']
        if alias['name'] == name
    )


def gateway_id():
    return json.loads(
        requests.get(
            endpoint('gateways'),
            headers=AUTH_HEADER,
            verify=False
        ).content
    )['items'][0]['id']


def attach_alias(gateway, interface, aliases):
    return json.loads(
        requests.patch(
            endpoint(
                'gateways/{gateway}/interfaces/{interface}'.format(
                    gateway=gateway,
                    interface=interface
                )
            ),
            headers=AUTH_HEADER,
            json={
                'aliases': aliases if isinstance(aliases, list) else [aliases]
            },
            verify=False
        ).content
    )


def activate_gateway(gateway_id):
    return json.loads(
        requests.patch(
            endpoint(
                'gateways/{gateway_id}'.format(
                    gateway_id=gateway_id,
                )
            ),
            headers=AUTH_HEADER,
            json={'active': True},
            verify=False
        ).content
    )

if __name__ == '__main__':
    gateway = gateway_id()
    mgmt = alias_by_name('mgmt')
    wan = alias_by_name('wan')
    lan = alias_by_name('lan')
    print(attach_alias(gateway, 'eth0', [mgmt, wan]))
    print(attach_alias(gateway, 'eth1', lan))
    print(activate_gateway(gateway))
