/* GPU geographic projection; one texture and one full-screen quad. */
window.AtlasRenderer = function(image) {
  const canvas=document.createElement('canvas');
  const gl=canvas.getContext('webgl',{alpha:true,premultipliedAlpha:false,antialias:false,preserveDrawingBuffer:true});
  if(!gl)return null;
  const vs='attribute vec2 p; void main(){gl_Position=vec4(p,0.,1.);}';
  const fs=`precision highp float;
  uniform sampler2D earth;
  uniform vec2 size,center;
  uniform float zoom,globe;
  uniform vec3 ocean,land;
  const float PI=3.141592653589793;
  void main(){
    vec2 xy=gl_FragCoord.xy-size*.5;
    float r=min(size.x,size.y)*.425*zoom;
    float lat,lon,shade=1.,alpha=1.;
    if(globe>.5){
      vec2 q=xy/r;float d=dot(q,q);
      if(d>=1.){gl_FragColor=vec4(0.);return;}
      float z=sqrt(1.-d),cl=cos(center.y),sl=sin(center.y);
      lat=asin(clamp(q.y*cl+z*sl,-1.,1.));
      lon=center.x+atan(q.x,z*cl-q.y*sl);
      shade=.70+.30*max(0.,z*.87-q.x*.35+q.y*.30);
      alpha=clamp((1.-sqrt(d))*r,0.,1.);
    }else{
      lon=center.x+xy.x*2.*PI/(size.x*zoom);
      lat=center.y+xy.y*2.*PI/(size.x*zoom);
      if(abs(lat)>PI*.5){gl_FragColor=vec4(0.);return;}
    }
    vec2 uv=vec2(fract(lon/(2.*PI)+.5),.5-lat/PI);
    float v=texture2D(earth,uv).r;
    gl_FragColor=vec4(mix(ocean,land,v)*shade,alpha);
  }`;
  function shader(type,src){const s=gl.createShader(type);gl.shaderSource(s,src);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));return s;}
  try{
    const program=gl.createProgram();gl.attachShader(program,shader(gl.VERTEX_SHADER,vs));gl.attachShader(program,shader(gl.FRAGMENT_SHADER,fs));gl.linkProgram(program);if(!gl.getProgramParameter(program,gl.LINK_STATUS))return null;
    gl.useProgram(program);const buffer=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,buffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1,1,-1,-1,1,1,1]),gl.STATIC_DRAW);const p=gl.getAttribLocation(program,'p');gl.enableVertexAttribArray(p);gl.vertexAttribPointer(p,2,gl.FLOAT,false,0,0);
    const tex=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,tex);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.REPEAT);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,image);
    const u=Object.fromEntries(['earth','size','center','zoom','globe','ocean','land'].map(k=>[k,gl.getUniformLocation(program,k)]));gl.uniform1i(u.earth,0);
    return {draw(w,h,lon,lat,zoom,mode,ocean,land){
      if(gl.isContextLost())return null;
      if(canvas.width!==w)canvas.width=w;if(canvas.height!==h)canvas.height=h;
      gl.viewport(0,0,w,h);gl.uniform2f(u.size,w,h);gl.uniform2f(u.center,lon*Math.PI/180,lat*Math.PI/180);gl.uniform1f(u.zoom,zoom);gl.uniform1f(u.globe,mode==='globe'?1:0);gl.uniform3fv(u.ocean,ocean.map(x=>x/255));gl.uniform3fv(u.land,land.map(x=>x/255));gl.drawArrays(gl.TRIANGLE_STRIP,0,4);return canvas;
    }};
  }catch{return null;}
};
