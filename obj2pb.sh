#!/usr/bin/env node

var protobuf = require('protobufjs');
var fs = require('fs');

var builder = protobuf.loadProto(fs.readFileSync('obj.proto'));
var filenames = process.argv.slice(2);


var Model = builder.build('Model');
var Mesh = Model.Mesh;
var Geometry = Mesh.Geometry;
var Vector3 = Geometry.Vector3;
var Face = Geometry.Face;

var vertex_pattern = /v( +[\d|\.|\+|\-|e]+)( +[\d|\.|\+|\-|e]+)( +[\d|\.|\+|\-|e]+)/;
var normal_pattern = /vn( +[\d|\.|\+|\-|e]+)( +[\d|\.|\+|\-|e]+)( +[\d|\.|\+|\-|e]+)/;
var uv_pattern = /vt( +[\d|\.|\+|\-|e]+)( +[\d|\.|\+|\-|e]+)/;

//var face_pattern1 = /f( +\d+)( +\d+)( +\d+)( +\d+)?/;
//var face_pattern2 = /f( +(\d+)\/(\d+))( +(\d+)\/(\d+))( +(\d+)\/(\d+))( +(\d+)\/(\d+))?/;
var face_pattern3 = /f( +(\d+)\/(\d+)\/(\d+))( +(\d+)\/(\d+)\/(\d+))( +(\d+)\/(\d+)\/(\d+))( +(\d+)\/(\d+)\/(\d+))?/;
//var face_pattern4 = /f( +(\d+)\/\/(\d+))( +(\d+)\/\/(\d+))( +(\d+)\/\/(\d+))( +(\d+)\/\/(\d+))?/

var vertices = 0,
    uvs = 0,
    normals = 0,
    faces = 0;

if(filenames.length === 2) {
    var i = filenames[0];
    var o = filenames[1];
    var result = null;

    var model = new Model('');

    linenum = 0;

    var lines = fs.readFileSync(i).toString().split("\n");
    var geometry = new Geometry(0);
    var material = '';

    lines.forEach(function(line) {

        linenum++;

        if(line.trim().length === 0 || line.charAt(0) === '#') {
            return;

        } else if((result = vertex_pattern.exec(line)) !== null) {
            geometry.vertices.push(new Vector3(
                parseFloat(result[1]),
                parseFloat(result[2]),
                parseFloat(result[3])
            ));
            vertices++;

        } else if((result = normal_pattern.exec(line)) !== null) {
            geometry.normals.push(new Vector3(
                parseFloat(result[1]),
                parseFloat(result[2]),
                parseFloat(result[3])
            ));
            normals++;

        } else if((result = uv_pattern.exec(line)) !== null) {
            geometry.uvs.push(new Vector3(
                parseFloat(result[1]),
                parseFloat(result[2])
            ));
            uvs++;

        } else if((result = face_pattern3.exec(line)) !== null) {
            geometry.faces.push(new Face(0,
                [ parseInt(result[2])-1, parseInt(result[6])-1, parseInt(result[10])-1 ],
                [ parseInt(result[3])-1, parseInt(result[7])-1, parseInt(result[11])-1 ],
                [ parseInt(result[4])-1, parseInt(result[8])-1, parseInt(result[12])-1 ]
            ));
            faces++;

        } else if(/^usemtl /.test(line)) {
            var mesh = new Mesh(geometry);
            mesh.material = material;
            model.meshes.push(mesh);
            geometry = new Geometry(0);

            material = line.substring(7);

        } else {
            console.log('Unhandled: ' + linenum + ': ' + line);
        }
    });


    var mesh = new Mesh(geometry);
    model.meshes.push(mesh);

    var wstream = fs.createWriteStream(o);
    var buffer = model.toBuffer();
    wstream.write(buffer);
    wstream.end();

    wstream = fs.createWriteStream(o+'.b64');
    buffer = model.encode64();
    wstream.write(buffer);
    wstream.end();

    console.log("STATS: ");
    console.log(" - Vertices: " + vertices);
    console.log(" - UVs:      " + uvs);
    console.log(" - Normals:  " + normals);
    console.log(" - Faces:    " + faces);


} else {
    console.log('Usage: conv.sh inputFile outputFile\n');
}
