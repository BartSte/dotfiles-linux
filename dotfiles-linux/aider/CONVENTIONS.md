When writing code, you MUST follow these principles:

- Code should be easy to read and understand.
- Keep the code as simple as possible. Avoid unnecessary complexity.
- Use meaningful names for variables, functions, etc. Names should reveal intent.
- Functions should be small and do one thing well. They should not exceed a few lines.
- Function names should describe the action being performed.
- Prefer fewer arguments in functions. Ideally, aim for no more than two or three.
- Only use comments when necessary, as they can become outdated. Instead, strive to make the code self-explanatory.
- When comments are used, they should add useful information that is not readily apparent from the code itself.
- Properly handle errors and exceptions to ensure the software's robustness.
- Use exceptions rather than error codes for handling errors.
- Organize functions and methods based on their call stack. When reading a function, each new self-implemented function call should be directly under it.
- Use the "step down rule" to order functions and methods, i.e, the higher-level appear first in a file, and as you “step down” through the code, you encounter increasingly detailed, lower-level functions.
