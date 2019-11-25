#!/usr/bin/env python

from __future__ import print_function
import sys
sys.path.append('/home/ahsans/work/plant_disease/tensorflow_models/models/research/slim') # add slim to PYTHONPATH
import tensorflow as tf

import numpy as np
import os

from datasets import imagenet
from nets import inception
from nets import resnet_v1
from nets import inception_utils
from nets import resnet_utils
from preprocessing import inception_preprocessing
from nets import nets_factory
from preprocessing import preprocessing_factory

def del_all_flags(FLAGS):
    flags_dict = FLAGS._flags()
    keys_list = [keys for keys in flags_dict]
    for keys in keys_list:
        FLAGS.__delattr__(keys)

def classify_image(infile):

    tf.app.flags.DEFINE_integer('num_classes', 38, 'The number of classes.')
#    tf.app.flags.DEFINE_string('infile',None, 'Image file, one image per line.')
    tf.app.flags.DEFINE_boolean('tfrecord',False, 'Input file is formatted as TFRecord.')
    tf.app.flags.DEFINE_string('outfile',None, 'Output file for prediction probabilities.')
    tf.app.flags.DEFINE_string('model_name', 'inception_v3', 'The name of the architecture to evaluate.')
    tf.app.flags.DEFINE_string('preprocessing_name', None, 'The name of the preprocessing to use. If left as `None`, then the model_name flag is used.')
    tf.app.flags.DEFINE_string('checkpoint_path', '/home/ahsans/work/plant_disease/plant_models/inception_v3_all/model.ckpt-100000','The directory where the model was written to or an absolute path to a checkpoint file.')
    tf.app.flags.DEFINE_integer('eval_image_size', None, 'Eval image size.')
    FLAGS = tf.app.flags.FLAGS

    slim = tf.contrib.slim

    model_name_to_variables = {'inception_v3':'InceptionV3','inception_v4':'InceptionV4','resnet_v1_50':'resnet_v1_50','resnet_v1_152':'resnet_v1_152'}
    #class_to_label = ['Squash Powdery Mildew', 'Apple Black Rot', 'Grape Black Rot', 'Peach Bacterial Spot', 'Tomato Leaf Mold']

    class_to_label = ['Apple___Apple_scab','Apple___Black_rot','Apple___Cedar_apple_rust', 'Apple___healthy', 'Blueberry___healthy', 'Cherry_including_sour___Powdery_mildew', 'Cherry_including_sour___healthy','Corn_maize___Cercospora_leaf_spot_Gray_leaf_spot', 'Corn_maize___Common_rust_', 'Corn_maize___Northern_Leaf_Blight', 'Corn_maize___healthy', 'Grape___Black_rot', 'Grape___Esca_Black_Measles', 'Grape___Leaf_blight_Isariopsis_Leaf_Spot', 'Grape___healthy', 'Orange___Haunglongbing_Citrus_greening', 'Peach___Bacterial_spot', 'Peach___healthy', 'Pepper_bell___Bacterial_spot', 'Pepper_bell___healthy', 'Potato___Early_blight', 'Potato___Late_blight', 'Potato___healthy', 'Raspberry___healthy', 'Soybean___healthy', 'Squash___Powdery_mildew', 'Strawberry___Leaf_scorch', 'Strawberry___healthy', 'Tomato___Bacterial_spot', 'Tomato___Early_blight', 'Tomato___Late_blight', 'Tomato___Leaf_Mold', 'Tomato___Septoria_leaf_spot', 'Tomato___Spider_mitesTwo-spotted_spider_mite', 'Tomato___Target_Spot', 'Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'Tomato___Tomato_mosaic_virus', 'Tomato___healthy']

    preprocessing_name = FLAGS.preprocessing_name or FLAGS.model_name
    eval_image_size = FLAGS.eval_image_size

    if FLAGS.tfrecord:
      fls = tf.python_io.tf_record_iterator(path=FLAGS.infile)
    else:
      fl = infile.strip()#[s.strip() for s in open(FLAGS.infile)]

    model_variables = model_name_to_variables.get(FLAGS.model_name)
    if model_variables is None:
      tf.logging.error("Unknown model_name provided `%s`." % FLAGS.model_name)
      sys.exit(-1)

    if FLAGS.tfrecord:
      tf.logging.warn('Image name is not available in TFRecord file.')

    if tf.gfile.IsDirectory(FLAGS.checkpoint_path):
      checkpoint_path = tf.train.latest_checkpoint(FLAGS.checkpoint_path)
    else:
      checkpoint_path = FLAGS.checkpoint_path

    image_string = tf.placeholder(tf.string) # Entry to the computational graph, e.g. image_string = tf.gfile.FastGFile(image_file).read()

    image = tf.image.decode_jpeg(image_string, channels=3, try_recover_truncated=True, acceptable_fraction=0.3) ## To process corrupted image files

    image_preprocessing_fn = preprocessing_factory.get_preprocessing(preprocessing_name, is_training=False)

    network_fn = nets_factory.get_network_fn(FLAGS.model_name, FLAGS.num_classes, is_training=False)

    if FLAGS.eval_image_size is None:
      eval_image_size = network_fn.default_image_size

    processed_image = image_preprocessing_fn(image, eval_image_size, eval_image_size)

    processed_images  = tf.expand_dims(processed_image, 0) # Or tf.reshape(processed_image, (1, eval_image_size, eval_image_size, 3))

    logits, _ = network_fn(processed_images)

    probabilities = tf.nn.softmax(logits)

    init_fn = slim.assign_from_checkpoint_fn(checkpoint_path, slim.get_model_variables(model_variables))

    sess = tf.Session()
    init_fn(sess)

    h = ['image']
    h.extend(['class%s' % i for i in range(FLAGS.num_classes)])
    h.append('predicted_class')
    image_name = None
    print(fl)
    try:
      if FLAGS.tfrecord is False:
        x = tf.gfile.FastGFile(fl, 'rb').read() # You can also use x = open(fl).read()
        image_name = os.path.basename(fl)
      else:
        example = tf.train.Example()
        example.ParseFromString(fl)

        # Note: The key of example.features.feature depends on how you generate tfrecord.
        x = example.features.feature['image/encoded'].bytes_list.value[0] # retrieve image string

        image_name = 'TFRecord'

      probs = sess.run(probabilities, feed_dict={image_string:x})

    except Exception as e:
      tf.logging.warn('Cannot process image file %s' % fl)
      print(e)
      #continue

    probs = probs[0, 0:]
    a = [image_name]
    a.extend(probs)
    a.append(class_to_label[np.argmax(probs)])

    sess.close()
    tf.reset_default_graph()
    del_all_flags(tf.flags.FLAGS)
    return (class_to_label[np.argmax(probs)])
