# Redefines a function so that it obtains a "lock" on the object
# before the function executes
def synchronized(func):
    def _synchronized(self, *args, **kwargs):
         with self.lock:
            return func(self, *args, **kwargs)
    return _synchronized
