import requests
from flask import Flask, request, render_template, make_response, redirect
import jwt
import subprocess
import json
import os

app = Flask(__name__)

SECRET_KEY='123'
#SECRET_KEY = os.environ['SECRET_KEY']

@app.route('/')
def index():
    return render_template('hashing.html')

@app.route('/login', methods=['POST'])
def login():
    # Send a login request to the first microservice
    username = request.form['username']
    password = request.form['password']
    #r = requests.post('http://localhost:5001/login', data={'username': username, 'password': password})
    if username == 'admin' and password == 'admin':
        # Generate a JWT
        token = jwt.encode({'sub': username}, SECRET_KEY, algorithm='HS256')
        resp = make_response(redirect('/protected'))
        resp.set_cookie('jwt', token)
        return resp
    else:
        return 'Invalid username or password', 401


@app.route('/protected')
def protected():
    # Check for a valid JWT in the cookie
    #jwt = request.cookies.get('jwt')
    #print (jwt)
    # Check for a valid JWT
    auth_header = request.cookies.get('jwt')
    if auth_header:
        print (auth_header)
        #token = auth_header.split(' ')[1]
        token = auth_header
        try:
            jwt.decode(token, SECRET_KEY, algorithms='HS256')
            return '<h1>Access granted. <!--This is your flag: {FLAG_superman}--></h1>'
        except jwt.DecodeError:
            return 'Invalid token', 401
    else:
        return 'Authentication required', 401


@app.route('/encode', methods=['POST'])
def encode():
    encoded_text = request.form['text']
    try:
        cmd = 'echo ' + encoded_text + '|base64'
        output = subprocess.check_output([cmd], shell=True)
        return output

    except Exception as e:
        return str(e), 500

@app.errorhandler(404)
def not_found(error):
    return render_template('404.html'), 404


@app.errorhandler(500)
def internal_error(error):
    return render_template('500.html'), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
