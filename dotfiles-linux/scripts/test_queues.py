#!/usr/bin/env python

from multiprocessing import Queue, Process
from queue import Empty
import time
from typing import Any
from unittest import TestCase


def put_sleep_get(queue: Any, sleep_sec: int = 1, repeat: int = 1):

    for _ in range(repeat):
        # Put an item in the queue
        queue.put("Hello from A")
        print("(put_sleep_get) Process A put an item in the queue")

        # Wait 1 second
        time.sleep(sleep_sec)

        # Get the item from the queue
        try:
            print("(put_sleep_get) Process A is trying to get the item from the queue")
            item = queue.get_nowait()
            print(f"(put_sleep_get) Process A got the item from the queue: {item}")
        except Empty:
            print("(put_sleep_get) Queue is empty")


def sleep_get(queue: Any, sleep_sec: int = 1):
    # Wait 1 second
    time.sleep(sleep_sec)

    # Get the item from the queue
    try:
        print("(sleep_get) Process B is trying to get the item from the queue")
        item = queue.get_nowait()
        print(f"(sleep_get) Process B got the item from the queue: {item}")
    except Empty:
        print("(sleep_get) Queue is empty")


class TestQueue(TestCase):

    def test_1_process(self):
        queue = Queue()
        p_put_sleep_get = Process(target=put_sleep_get, args=(queue, 1))
        p_put_sleep_get.start()
        p_put_sleep_get.join()

    def test_2_process(self):
        queue = Queue()
        p_put_sleep_get = Process(target=put_sleep_get, args=(queue, 3))
        p_sleep_get = Process(target=sleep_get, args=(queue, 1))

        p_put_sleep_get.start()
        p_sleep_get.start()

        p_put_sleep_get.join()
        p_sleep_get.join()

    def test_3_process(self):
        queue = Queue()
        p_put_sleep_get = Process(target=put_sleep_get, args=(queue, 3, 3))
        p_sleep_get = Process(target=sleep_get, args=(queue, 1))
        p2_sleep_get = Process(target=sleep_get, args=(queue, 1))

        p_put_sleep_get.start()
        p_sleep_get.start()
        time.sleep(3)
        p2_sleep_get.start()

        p_put_sleep_get.join()
        p_sleep_get.join()
        p2_sleep_get.join()
        
