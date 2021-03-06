diameter = 85.5;
height = 2;
lip_inset = 2;
lip_pit = 3.5;
lip_height = 1;
glass_diameter_outer = 81.5;

motion_detector_diameter = 23.3;
motion_detector_lens_clearance = 1;
motion_detector_bottom_h = 5;
motion_detector_pcb = [25.5, 35.7, 1.2];
motion_detector_pcb_parts = [25, 35, 3];

motion_detector_bracket_w=5;
motion_detector_bracket_hole=1;

battery = [34, 52, 10];
battery_z  = motion_detector_bottom_h + motion_detector_pcb[2] + motion_detector_pcb_parts[2] + 1;

feather = [23, 50, 12];
feather_bracket_w = 4;
feather_bracket_bottom_h = battery_z + battery[2] + 1;
feather_bracket_hole = 1;
feather_bracket_hole_from_edge_a = 2.5;
feather_bracket_hole_from_edge_b = 2.1;

photo_sensor_rotation = [0, 0, 0];
photo_sensor_offset = [0, feather[1]/2, 0];
photo_sensor_r = 5/2;
photo_sensor_h = 2;
photo_sensor_cut = 0.5;
photo_sensor_lead_h = 24;
photo_sensor_lead_hole_r = 0.25;

$fn = 120;
smidge = 0.01;

//mockup();

// Set up for printing
rotate([180,0,0])
  lid();

////////////////////////////////////////////////////////////

module lid() {
  radius = diameter/2;

  difference() {
    union() {
      cylinder(r=radius, h=height);

    // motion sensor bracket
    motion_detector_bracket_offset = motion_detector_diameter/2 + motion_detector_lens_clearance;
    for(r = [0 : 180 : 180])
      rotate([0, 0, r]) {
        translate([-motion_detector_pcb[0]/2, motion_detector_bracket_offset, -motion_detector_bottom_h])
          motion_detector_bracket();
        // Feather bracket
        translate([-feather[0]/2, -feather[1]/2, -feather_bracket_bottom_h]) {
          if (r == 0) {
            feather_bracket(feather_bracket_hole_from_edge_a);
          } else {
            feather_bracket(feather_bracket_hole_from_edge_b);
          }
        }
        // joiner between parts for support
        translate([-feather[0]/2, motion_detector_bracket_offset + motion_detector_bracket_w, -motion_detector_bottom_h])
          cube([feather[0], feather[1]/2 - motion_detector_bracket_offset - motion_detector_bracket_w, motion_detector_bottom_h]);
      }
    }

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

        translate([0, 0, -feather_bracket_bottom_h-0.5-smidge])
        cylinder(r=photo_sensor_r, h=feather_bracket_bottom_h+smidge);
      }
  }
}

module feather_bracket(feather_bracket_hole_from_edge) {
    difference() {
      cube([feather[0], feather_bracket_w, feather_bracket_bottom_h ]);
      translate([feather_bracket_hole_from_edge, feather_bracket_w/2, -smidge])
        cylinder(r=feather_bracket_hole, h=feather_bracket_bottom_h - 2);
      translate([feather[0]-feather_bracket_hole_from_edge, feather_bracket_w/2, -smidge])
        cylinder(r=feather_bracket_hole, h=feather_bracket_bottom_h - 2);
    }

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
  color("green")
  translate(photo_sensor_offset + [0, 0, 0.5])
    rotate(photo_sensor_rotation)
      photo_resistor();

  // board
  color("blue")
    translate([-feather[0]/2, -feather[1]/2, -feather_bracket_bottom_h-feather[2]])
    feather();

  // battery
  color("orange")
    rotate([0, 0, 90])
      translate([-battery[0]/2, -battery[1]/2, -battery_z-battery[2]])
        battery();

  // glass
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
  translate([0, 0, -motion_detector_bottom_h - motion_detector_pcb[2]]) {
    translate([-motion_detector_pcb[0]/2, -motion_detector_pcb[1]/2, 0])
      difference() {
        cube(motion_detector_pcb);
        translate([motion_detector_pcb[0]/2, 3, -smidge])
          cylinder(r=1.5, h=motion_detector_pcb[2]+smidge*2);
        translate([motion_detector_pcb[0]/2, motion_detector_pcb[1] -3, -smidge])
          cylinder(r=1.5, h=motion_detector_pcb[2]+smidge*2);
      }
      translate([-motion_detector_pcb_parts[0]/2, -motion_detector_pcb_parts[1]/2, -motion_detector_pcb_parts[2]])
        cube(motion_detector_pcb_parts);
    }
}

module feather() {
  cube(feather);
}

module battery() {
  cube(battery);
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
  translate([-2.7/2, 0, -photo_sensor_lead_h])
  cylinder(r=photo_sensor_lead_hole_r, h=photo_sensor_lead_h);
  translate([2.7/2, 0, -photo_sensor_lead_h])
  cylinder(r=photo_sensor_lead_hole_r, h=photo_sensor_lead_h);
  }
