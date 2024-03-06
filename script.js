(async () => {
  async function getShader(url) {
    try {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      return await response.text();
    } catch (error) {
      console.error("There was a problem with the fetch operation:", error);
      return null;
    }
  }

  // WebGl init
  const canvas = document.getElementById("canvas");
  const gl = canvas.getContext("webgl");
  if (!gl) {
    return;
  }

  // Vertex shader source code
  const vertexShaderSource = await getShader("vertex.glsl");

  // Fragment shader source code
  const fragmentShaderSource = await getShader("fragment.glsl");

  if (!vertexShaderSource || !fragmentShaderSource) {
    console.log("Shader null");
    return;
  }

  function createShader(gl, type, source) {
    let shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    let success = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
    if (success) {
      return shader;
    }

    console.log(gl.getShaderInfoLog(shader));
    gl.deleteShader(shader);
  }

  function createProgram(gl, vertexShader, fragmentShader) {
    let program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);
    let success = gl.getProgramParameter(program, gl.LINK_STATUS);
    if (success) {
      return program;
    }

    console.log(gl.getProgramInfoLog(program));
    gl.deleteProgram(program);
  }

  const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexShaderSource);
  const fragmentShader = createShader(
    gl,
    gl.FRAGMENT_SHADER,
    fragmentShaderSource
  );
  const shaderProgram = createProgram(gl, vertexShader, fragmentShader);
  gl.useProgram(shaderProgram);

  // Define vertex positions (covering the whole screen)
  const positions = [-1, 1, 1, 1, -1, -1, 1, -1];

  // Create buffer
  const positionBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);

  // Get attribute location
  const positionAttributeLocation = gl.getAttribLocation(
    shaderProgram,
    "a_position"
  );

  // Specify how to pull the data out
  gl.enableVertexAttribArray(positionAttributeLocation);
  gl.vertexAttribPointer(positionAttributeLocation, 2, gl.FLOAT, false, 0, 0);

  // Program uniforms
  const timeLocation = gl.getUniformLocation(shaderProgram, "time");
  const viewportLocation = gl.getUniformLocation(shaderProgram, "viewport");
  const speedlinesLocation = gl.getUniformLocation(shaderProgram, "speedlines");

  gl.uniform1i(speedlinesLocation, 0);
  let timeTick = 0.001;

  const linkElements = document.getElementsByClassName("link");
  for (const link of linkElements) {
    link.addEventListener("mouseover", () => {
      timeTick = 0.002;
      gl.uniform1i(speedlinesLocation, 1);
    });

    link.addEventListener("mouseout", () => {
      timeTick = 0.001;
      gl.uniform1i(speedlinesLocation, 0);
    });
  }

  function resizeCanvas() {
    // Lookup the size the browser is displaying the canvas in CSS pixels.
    var displayWidth = canvas.clientWidth;
    var displayHeight = canvas.clientHeight;

    // Check if the canvas is not the same size.
    if (canvas.width !== displayWidth || canvas.height !== displayHeight) {
      // Make the canvas the same size
      canvas.width = displayWidth / 2;
      canvas.height = displayHeight / 2;

      // Update WebGL viewport
      gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
      gl.uniform2f(
        viewportLocation,
        gl.drawingBufferWidth,
        gl.drawingBufferHeight
      );
    }
  }

  // Call the resizeCanvas function whenever the window is resized
  window.addEventListener("resize", resizeCanvas, false);
  resizeCanvas();

  let timePassed = 0.0;
  function renderCanvas() {
    // Pass uniforms
    timePassed += timeTick;
    gl.uniform1f(timeLocation, timePassed);

    // Clear the canvas
    gl.clearColor(0, 0, 0, 1);
    gl.clear(gl.COLOR_BUFFER_BIT);

    // Draw the rectangle
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

    requestAnimationFrame(renderCanvas);
  }
  requestAnimationFrame(renderCanvas);
})();
