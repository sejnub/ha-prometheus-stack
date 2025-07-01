#!/usr/bin/env python3

import json
import sys
import yaml

def generate_alertmanager_config(options_file, output_file):
    """Generate alertmanager.yml from options.json using the same logic as the add-on."""
    try:
        with open(options_file, 'r') as f:
            options = json.load(f)

        # Base configuration
        config = {
            'global': {
                'resolve_timeout': '5m',
            },
            'route': {
                'group_by': ['alertname'],
                'group_wait': '30s',
                'group_interval': '5m',
                'repeat_interval': '12h',
                'receiver': 'default'
            },
            'receivers': [{'name': 'default'}]
        }

        # Process notification settings
        if 'notification_settings' in options:
            settings = options['notification_settings']
            
            # Update global settings if provided
            if 'resolve_timeout' in settings:
                config['global']['resolve_timeout'] = settings['resolve_timeout']
            
            # Update route settings if provided
            route_settings = ['group_by', 'group_wait', 'group_interval', 'repeat_interval']
            for setting in route_settings:
                if setting in settings:
                    config['route'][setting] = settings[setting]

        # Process notification modules
        receivers = []
        if 'notification_modules' in options:
            for module in options['notification_modules']:
                if not module.get('enabled', True):
                    continue

                receiver = {'name': module['name']}
                
                # Add module-specific configuration
                module_type = module['type'].lower()
                if module_type == 'email':
                    receiver['email_configs'] = [{
                        'to': module['recipient'],
                        'from': module.get('sender', ''),
                        'smarthost': module['server'],
                        'auth_username': module.get('username', ''),
                        'auth_password': module.get('password', ''),
                        'require_tls': module.get('require_tls', True)
                    }]
                elif module_type == 'ntfy':
                    receiver['webhook_configs'] = [{
                        'url': f"{module['server']}/{module['topic']}",
                        'send_resolved': True
                    }]
                elif module_type == 'pushover':
                    receiver['pushover_configs'] = [{
                        'user_key': module['user_key'],
                        'token': module['api_token']
                    }]
                elif module_type == 'telegram':
                    receiver['telegram_configs'] = [{
                        'bot_token': module['bot_token'],
                        'chat_id': module['chat_id'],
                        'parse_mode': 'HTML'
                    }]
                elif module_type == 'webhook':
                    receiver['webhook_configs'] = [{
                        'url': module['url'],
                        'send_resolved': True
                    }]

                receivers.append(receiver)

        # Update receivers and default route
        if receivers:
            config['receivers'] = receivers
            config['route']['receiver'] = receivers[0]['name']

        # Write configuration
        with open(output_file, 'w') as f:
            yaml.dump(config, f, default_flow_style=False, sort_keys=False)
        
        return True

    except Exception as e:
        print(f"Error generating alertmanager config: {str(e)}", file=sys.stderr)
        return False

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: generate_alertmanager_config.py <options.json> <output.yml>", file=sys.stderr)
        sys.exit(1)
    
    success = generate_alertmanager_config(sys.argv[1], sys.argv[2])
    sys.exit(0 if success else 1) 