When writing python code, you also MUST follow these principles:

- Add type hints to where possible. You MUST follow these principles:

  - Where possible, use builtin types instead of those from `typing` (for example, `list` instead of `List`)
  - Where possible, import types from `collections.abc`.
  - Do not use `Optional` but use ` | None` instead
  - Try to avoid dynamic imports and relative imports.

- Add docstrings to the code that using Google docstrings. For example:

  ```python
  class Point:
      """Represents a 2D Point."""

      x: int
      y: int

      def __init__(self, x: int, y: int) -> None:
          """Init.
          Args:
            x: the x coordinate.
            y: the y coordinate.
          """
          self.x = x
          self.y = y

  def add(a: int, b: int) -> int:
    """Adds two numbers.

    Args:
        a: the first number.
        b: the second number.

    Returns:
        Sum of the two numbers.
    """
    return a + b
  ```

- When writing unittests follow these principles:
  - make use of the `unittest` framework's `TestCase` class to construct your test cases.
  - try to avoid the usage of the `unittest.mock` module as the primary strategy to write your tests. Instead, focus on testing against the actual implementation.
