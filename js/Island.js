
Island = function() {
	
	// 3d objects
	var objects = {};
	
	// 3d settings
	var settings = { description: "Settings for the 3d renderer."
		, perspective: 20
		, near: 1
		, far: 10000
		, camera_max_height: 2000
		, velocity: { x: 0, y: 0 }
		, mouse_down: false
	};
		
	// island settings
	var island_settings = { description: "Island settings"
		, width: 500
		, height: 500
		, height_factor: 10
		, smoothing: 2 // number of smoothing steps
		, colors: [0x3E7FC9, 0x15BAE8, 0xCFC436, 0xA9CC1D, 0x52942C, 0x10631B, 0xBACBD9]
	};
	
	this.render = function() {
		objects.renderer.render(objects.scene, objects.camera);
	};
	
	// initialize the 3d renderer
	(function() {
		objects.renderer = new THREE.WebGLRenderer();
        objects.renderer.setSize(window.innerWidth, window.innerHeight);
		$("body").append(objects.renderer.domElement);
			
		// Scene
        objects.scene = new THREE.Scene();
			
		// Camera
        objects.camera = new THREE.PerspectiveCamera(
			settings.perspective,
			window.innerWidth / window.innerHeight,
			settings.near,
			settings.far
		);
		objects.camera.lookAt(objects.scene.position);
		objects.camera.position = new THREE.Vector3(0,-1000,settings.camera_max_height);
		objects.camera.lookAt(objects.scene.position);
		objects.scene.add(objects.camera);
			
		// Light
		var point_light = new THREE.PointLight( 0xFFFFFF );
		point_light.position = new THREE.Vector3(-1000,-1000,1000);
		objects.scene.add(point_light);
			
		// Plane
		var plane = new THREE.Mesh(
			new THREE.PlaneGeometry(island_settings.width*4,island_settings.height*4),
			new THREE.MeshLambertMaterial({ color: island_settings.colors[0] })
		);
        plane.overdraw = false;
		plane.position.y = -1;
		objects.scene.add(plane);
			
		render();
	})();
	
};

var island;
$(document).ready(function(){
	if(Modernizr.webgl) {
		// stop the text cursor
		document.onselectstart = function() { return false; };
		
		island = new Island();
	}
});

