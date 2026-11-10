import ast, json, os, sys, tempfile, time

# Read deploy_app.py and execute it in a mocked namespace
exec(open(r'd:\project\3D app\deploy_app.py', encoding='utf-8').read(), {
    '__file__': 'deploy_app.py',
    '__name__': '__main__',
    'subprocess': None,
    'sys': sys,
    'time': time,
    'os': os,
    'argparse': None,
})
