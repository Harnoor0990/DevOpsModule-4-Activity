from flask import Flask, request, render_template
import socket

app = Flask(__name__)

def get_container_ip():
    try:
        hostname = socket.gethostname()
        ip_address = socket.gethostbyname(hostname)
        return ip_address
    except Exception:
        return "Unknown"

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        name = request.form.get('name', 'Guest')
        ip_address = get_container_ip()
        greeting = f"Hello {name}, I am greeting you from a Python container with IP address {ip_address}"
        return render_template('index.html', greeting=greeting)

    return render_template('index.html', greeting=None)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
