import requests
from flask import Flask, request, render_template
import subprocess

app = Flask(__name__)
#Flag_1:{Flag_ThisIsFlag_1_000000}
#SECRET_KEY = os.environ['SECRET_KEY']

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/login', methods=['POST'])
def login():
    # Get the username and password from the request
    username = request.form['username']
    password = request.form['password']

    # Send a POST request to the second microservice with the username and password
    url = 'http://microservice2.default.svc.cluster.local:5001/login'
    payload = {'username': username, 'password': password}
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    response = requests.post(url, data=payload, headers=headers)
    #print (response.text)

    # Check the response from the second microservice
    if response.status_code == 200:
        # Login successful
        return (response.text)
    else:
        # Login failed
        return 'Login failed'

@app.route('/encode')
def index():
    return render_template('hashing.html')

@app.route('/encservice', methods=['POST'])
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
    app.run(host='0.0.0.0', port=8080)
