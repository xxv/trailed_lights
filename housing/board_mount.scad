diameter = 84.4;
height = 2;
lip_inset = 2;
lip_pit = 3;
lip_height = 1;
glass_diameter_outer = 81.5;

motion_detector_diameter = 23.3;
motion_detector_bottom_h = 5;
motion_detector_pcb = [25.5, 35.7, 1.2];

motion_detector_bracket_w=5;
motion_detector_bracket_hole=0.75;

photo_sensor_rotation = [0, 0, 90];
photo_sensor_offset = [-15, 0, 0];
photo_sensor_r = 5/2;
photo_sensor_h = 2;
photo_sensor_cut = 0.5;

feather = [23, 51, 12];

$fn=120;
smidge=0.01;

mockup();
//lid();

module lid() {
  radius = diameter/2;

  difference() {
    cylinder(r=radius, h=height);

    // lip inset
    translate([0, 0, -lip_height])
      difference() {
        cylinder(r=radius - lip_inset, h=height);
        translate([0,0,-smidge])
          cylinder(r=radius - lip_inset - lip_pit, h=height+smidge*2);
      }

    // motion detector hole
    translate([0,0,-smidge])
      cylinder(r=motion_detector_diameter/2, h=height+smidge*2);

    // photo sensor hole
    translate(photo_sensor_offset - [0, 0, -0.5])
      rotate(photo_sensor_rotation) {
        cut_cylinder(r=photo_sensor_r + 0.25, h=height + smidge*2, cut = photo_sensor_cut);
        translate([0, 0, smidge])
        photo_resistor();
        }
  }
  // motion sensor bracket
  translate([-motion_detector_pcb[0]/2, motion_detector_diameter/2 + 0.5, -motion_detector_bottom_h])
    motion_detector_bracket();
  translate([-motion_detector_pcb[0]/2, -motion_detector_diameter/2 - 0.5 - motion_detector_bracket_w, -motion_detector_bottom_h])
    motion_detector_bracket();
}

module motion_detector_bracket() {
    difference() {
      cube([motion_detector_pcb[0], motion_detector_bracket_w, motion_detector_bottom_h]);
      translate([motion_detector_pcb[0]/2, motion_detector_bracket_w/2, -smidge])
        cylinder(r=motion_detector_bracket_hole, h=motion_detector_bottom_h - 2);
    }
}

module mockup() {
  lid();
  color("red")
    motion_detector();
  translate(photo_sensor_offset)
    rotate(photo_sensor_rotation)
      photo_resistor();

  // board
  color("blue")
    translate([-feather[0]/2, -feather[1]/2, -feather[2] - motion_detector_bottom_h - motion_detector_pcb[2]])
    feather();
  % translate([0, 0, -121])
  difference() {
    cylinder(r=glass_diameter_outer/2, h=121);
    translate([0, 0, 2])
    cylinder(r=glass_diameter_outer/2-lip_pit, h=121-2);
    }
}

module motion_detector() {
  difference() {
    sphere(r=motion_detector_diameter/2);
    translate([-motion_detector_diameter/2, -motion_detector_diameter/2, -motion_detector_diameter])
      cube([motion_detector_diameter,
            motion_detector_diameter,
            motion_detector_diameter]);
  }
  translate([-motion_detector_diameter/2, -motion_detector_diameter/2, -5])
    cube([motion_detector_diameter,
          motion_detector_diameter,
          5]);
  // PCB
  translate([-motion_detector_pcb[0]/2, -motion_detector_pcb[1]/2, -motion_detector_bottom_h - motion_detector_pcb[2]])
    difference() {
      cube(motion_detector_pcb);
      translate([motion_detector_pcb[0]/2, 3, -smidge])
        cylinder(r=1.5, h=motion_detector_pcb[2]+smidge*2);
      translate([motion_detector_pcb[0]/2, motion_detector_pcb[1] -3, -smidge])
        cylinder(r=1.5, h=motion_detector_pcb[2]+smidge*2);
    }
}

module feather() {
  cube(feather);
  }

module cut_cylinder(r, h, cut) {
  intersection() {
    cylinder(r=r, h=h);
    translate([-r, -r + cut, 0])
    cube([r * 2, r * 2 - cut * 2, h+smidge*2]);
  }
}

module photo_resistor() {
  height = 2;
  cut_cylinder(r=photo_sensor_r, h=photo_sensor_h, cut=photo_sensor_cut);
  lead_h=24;
  translate([-2.7/2, 0, -lead_h])
  cylinder(r=0.25, h=lead_h);
  translate([2.7/2, 0, -lead_h])
  cylinder(r=0.25, h=lead_h);
  }
