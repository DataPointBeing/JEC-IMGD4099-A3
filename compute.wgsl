@group(0) @binding(0) var<uniform> res: vec2f;
@group(0) @binding(1) var<uniform> Da: f32;
@group(0) @binding(2) var<uniform> Db: f32;
@group(0) @binding(3) var<uniform> f: f32;
@group(0) @binding(4) var<uniform> k: f32;
@group(0) @binding(5) var<uniform> mseState: vec3f;
@group(0) @binding(6) var<uniform> funColor: vec3f;
@group(0) @binding(7) var<uniform> frames: f32;
@group(0) @binding(8) var<storage, read_write> stAin: array<f32>;
@group(0) @binding(9) var<storage, read_write> stAout: array<f32>;
@group(0) @binding(10) var<storage, read_write> stBin: array<f32>;
@group(0) @binding(11) var<storage, read_write> stBout: array<f32>;
@group(0) @binding(12) var<storage, read_write> stColin: array<f32>;
@group(0) @binding(13) var<storage, read_write> stColout: array<f32>;

fn index(x:i32, y:i32) -> u32 {
  let _res = vec2i(res);
  return u32( (y % _res.y) * _res.x + ( x % _res.x ) );
}

fn laplaceA(x:i32, y:i32) -> f32 {
  var total = stAin[index(x, y)] * -1.0;

  // Adjacent
  total += stAin[index(x + 1, y)] * 0.2;
  total += stAin[index(x - 1, y)] * 0.2;
  total += stAin[index(x, y + 1)] * 0.2;
  total += stAin[index(x, y - 1)] * 0.2;

  // Diagonal
  total += stAin[index(x + 1, y + 1)] * 0.05;
  total += stAin[index(x - 1, y - 1)] * 0.05;
  total += stAin[index(x + 1, y - 1)] * 0.05;
  total += stAin[index(x - 1, y + 1)] * 0.05;

  return total;
}

fn laplaceB(x:i32, y:i32) -> f32 {
  var total = stBin[index(x, y)] * -1.0;

  // Adjacent
  total += stBin[index(x + 1, y)] * 0.2;
  total += stBin[index(x - 1, y)] * 0.2;
  total += stBin[index(x, y + 1)] * 0.2;
  total += stBin[index(x, y - 1)] * 0.2;

  // Diagonal
  total += stBin[index(x + 1, y + 1)] * 0.05;
  total += stBin[index(x - 1, y - 1)] * 0.05;
  total += stBin[index(x + 1, y - 1)] * 0.05;
  total += stBin[index(x - 1, y + 1)] * 0.05;

  return total;
}

fn blendAdjacentColors(x:i32, y:i32) {
  var total = stAin[index(x, y)] * -1.0;

  let idx = index(x, y);

  var myRGB : vec3f = vec3f(stColin[idx*3], stColin[(idx*3)+1], stColin[(idx*3)+2]);

  var colorTotal : vec3f = vec3f(0.);
  var substanceTotal : f32 = 0.;
  for(var i : i32 = 0; i < 9; i++) {
      let offsetX = (i % 3) - 1;
      let offsetY = (i / 3) - 1;

      var weight : f32 = 0;
      if(offsetX == offsetY) {
        continue;
      }
      else if(offsetX == 0 || offsetY == 0) {
        weight = 0.2;
      }
      else {
        weight = 0.05;
      }

      let thisIdx = index(x + offsetX, y + offsetY);

      let thisRGB : vec3f = vec3f(stColin[thisIdx*3], stColin[(thisIdx*3)+1], stColin[(thisIdx*3)+2]);

      myRGB = mix(myRGB, thisRGB, stBin[thisIdx] * weight);
  }

  stColout[idx*3] = myRGB.x;
  stColout[(idx*3)+1] = myRGB.y;
  stColout[(idx*3)+2] = myRGB.z;
}

@compute
@workgroup_size(16, 16)
fn cs( @builtin(global_invocation_id) _cell:vec3u ) {
  let cell = vec3i(_cell);

  let x = cell.x;
  let y = cell.y;
  let i = index(x, y);

  if(mseState.z == 1.0 && distance(vec2(f32(x), f32(y)), mseState.xy) < 40){
    stAout[i] = 0.2;
    stBout[i] = 1.;
    stColout[i*3] = funColor.x;
    stColout[(i*3)+1] = funColor.y;
    stColout[(i*3)+2] = funColor.z;
    return;
  }

  let A = stAin[i];
  let B = stBin[i];

  stAout[i] = clamp(A + (Da * laplaceA(x, y)) - (A*B*B) + (f * (1-A)), 0, 1);
  stBout[i] = clamp(B + (Db * laplaceB(x, y)) + (A*B*B) - (B * (k+f)), 0, 1);

  blendAdjacentColors(x, y);
}
