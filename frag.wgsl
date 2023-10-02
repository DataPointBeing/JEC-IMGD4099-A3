@group(0) @binding(0) var<uniform> res:   vec2f;
@group(0) @binding(8) var<uniform> frames: f32;
@group(0) @binding(10) var<storage> stBin: array<f32>;
@group(0) @binding(12) var<storage> stColin: array<f32>;

@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
  let x = pos.x - (res.x/2);
  let idx : u32 = u32( pos.y * res.x + x );
  let y = stBin[idx];

  var funRGB : vec3f = vec3f(stColin[idx*3], stColin[(idx*3)+1], stColin[(idx*3)+2]);

  var bg : vec3f = vec3(0.114, 0.306, 0.569);
  if (pos.x % 50 > 48 || pos.y % 50 > 48) {
    bg = vec3(0.09, 0.210, 0.440);
  }

  if (y > 0.3 && stBin[u32((pos.y - 3) * res.x + (x + 3))] < 0.1 && stBin[u32((pos.y - 2) * res.x + (x + 2))] > 0.1) {
    funRGB = vec3(1.0);
  }
  else if (y > 0.3 && stBin[u32((pos.y - 1) * res.x + (x + 1))] < 0.1) {
    funRGB = funRGB * funRGB;
  }

  funRGB = mix(bg, funRGB, saturate(log(y + 0.1) + 1));

  if (y < 0.3 && stBin[u32((pos.y - 3) * res.x + (x + 3))] > 0.3 && idx%2 == 0) {
    let tempIndex = u32((pos.y - 2) * res.x + (x + 2));
    let otherRGB : vec3f = vec3f(stColin[tempIndex*3], stColin[(tempIndex*3) + 1], stColin[(tempIndex*3) + 2]);
    funRGB = mix(funRGB, otherRGB * otherRGB * 0.5, stBin[u32((pos.y - 2) * res.x + (x + 2))]);
  }

  return vec4(funRGB, 1.0);
}
