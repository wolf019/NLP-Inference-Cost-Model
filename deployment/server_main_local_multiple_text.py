from datetime import date
import numpy as np
import tensorflow as tf
import simplejson
import logging
import time
from flask import Flask, jsonify, request, Response, g as app_ctx
from flask import current_app, g as app_ctx
from transformers import BertTokenizer, BertTokenizerFast, AlbertTokenizer, AlbertTokenizerFast, RobertaTokenizer, RobertaTokenizerFast, DistilBertTokenizer,DistilBertTokenizerFast, TFAutoModelForSequenceClassification
from datetime import datetime


# Logging configuration
# logging_client = google.cloud.logging.Client()
# logging_client.setup_logging()

# logger = logging.getLogger('text-classification-model')
# logger.setLevel(logging.INFO)

app = Flask(__name__)

# Parameters

# Parameters
dataset_name = 'ag_news'
num_targets = 4 
model_name = "bert-large-uncased"
max_length = 512

# Class names
class_names = {
    0: "World",
    1: "Sports",
    2: "Business",
    3: "Sci/Tech"
}

# Load tokenizer
tokenizer = BertTokenizerFast.from_pretrained(model_name, do_lower_case=True)

# Load model
model = TFAutoModelForSequenceClassification.from_pretrained(model_name, num_labels=num_targets)
model.load_weights(f"../models/{model_name}-trained/tf_model.h5")

@app.before_request
def logging_before():
    # Store the start time for the request
    app_ctx.start_time = time.perf_counter()


@app.route("/isalive")
def isalive():
    return Response(status=200)

# Serve the model


@app.route('/predict', methods=['GET', 'POST'])
def prediction():
    # Time stamp start of inference
    # start = datetime.now()
    req = request.get_json(silent=True, force=True)
    # text = req['instances'][0]["text"]
    if not req:
        return jsonify(code=403, message="bad request")
    else:
        result = []
        for i in range(len(req['instances'])):
            tokenized_text = tokenizer.encode(
                req['instances'][i]['text'], truncation=True, padding=True, return_tensors="tf")
            class_names[np.argmax(tf.nn.softmax(
                model(tokenized_text)[0], axis=1).numpy())]
            result.append(class_names[np.argmax(tf.nn.softmax(
                model(tokenized_text)[0], axis=1).numpy())])

        return jsonify(predictions=result)


@ app.after_request
def logging_after(response):
    # Get total time in milliseconds
    total_time = time.perf_counter() - app_ctx.start_time
    time_in_ms = int(total_time * 1000)
    # Log the time taken for the endpoint
    current_app.logger.info('%s ms %s %s %s', time_in_ms,
                            request.method, request.path, dict(request.args))
    return response


if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=8080)

# local terminal requests with:
# curl -H "Content-Type: application/json" -X POST -d '{
#     "instances": [
#         {"text": "Fears for T N pension after talks Unions representing workers at Turner Newall say they are 'disappointed' after talks with stricken parent firm Federal Mogul."}
#     ]
# }' localhost:8080/predict
