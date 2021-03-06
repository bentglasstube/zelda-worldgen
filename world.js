var create_world = function(target) {
  var self = {
    width: 32,
    height: 21,
    openness: 0.5,
    target: target,
    delay: 10,
  };

  var roomNumber = 0;
  var new_room = function(value) {
    var self = {
      id: 'r' + (roomNumber++),
      walls: value,
      special: '',
    };

    self.add = function(d) {
      this.walls = this.walls | d;
      this.update();
    };

    self.remove = function(d) {
      this.walls = this.walls & (15 - d);
      this.update();
    };

    self.update = function() {
      var td = document.getElementById(this.id);
      if (td) {
        td.className = 'r' + this.walls;
        td.innerHTML = this.special;
      }
    };

    return self;
  }

  var TOP    = 1;
  var RIGHT  = 2;
  var BOTTOM = 4;
  var LEFT   = 8;

  self.unvisited = function(x, y) {
    if (x < 0 || x >= this.width) return false;
    if (y < 0 || y >= this.height) return false;
    return this.rooms[y][x].walls == 15;
  };

  self.destroy_wall = function(x, y, d) {
    if (d == TOP) {
      this.rooms[y][x].remove(TOP);
      this.rooms[y + 1][x].remove(BOTTOM);
    } else if (d == BOTTOM) {
      this.rooms[y][x].remove(BOTTOM);
      this.rooms[y - 1][x].remove(TOP);
    } else if (d == RIGHT) {
      this.rooms[y][x].remove(RIGHT);
      this.rooms[y][x + 1].remove(LEFT);
    } else if (d == LEFT) {
      this.rooms[y][x].remove(LEFT);
      this.rooms[y][x - 1].remove(RIGHT);
    }
  };

  self.render = function() {
    var html = '<table class="map"><tbody>';
    for (var y = this.height - 1; y >= 0; --y) {
      html += '<tr>';
      for (var x = 0; x < this.width; ++x) {
        var room = this.rooms[y][x];
        html += '<td id="' + room.id + '" class="r' + room.walls + '">' + room.special + '</td>';
      }
      html += '</tr>';
    }

    html += '</tbody></table>';

    var elem = document.getElementById(this.target);
    elem.innerHTML = html;
  };

  self.stack = [];

  self._iterate = function() {
    switch (this.stage) {
      case 'init':
        document.getElementById('progress').innerHTML = 'Initializing';

        this.rooms = [];

        for (var y = 0; y < this.height; ++y) {
          this.rooms[y] = [];
          for (var x = 0; x < this.width; ++x) {
            this.rooms[y][x] = new_room(15);
          }
        }

        this.x = Math.floor(this.width / 2);
        this.y = Math.floor(this.height / 2);
        this.rooms[this.y][this.x].special = 'S';

        this.render();

        this.iterate('maze');

        break;

      case 'maze':
        document.getElementById('progress').innerHTML = 'Building maze';

        var ways = [];
        var x = this.x;
        var y = this.y;

        if (this.unvisited(x, y + 1)) ways.push(TOP);
        if (this.unvisited(x, y - 1)) ways.push(BOTTOM);
        if (this.unvisited(x + 1, y)) ways.push(RIGHT);
        if (this.unvisited(x - 1, y)) ways.push(LEFT);

        if (ways.length == 0) {
          if (this.stack.length > 0) {
            var cell = this.stack.pop();
            this.x = cell.x;
            this.y = cell.y;
            this._iterate();
          } else {
            this.x = 0;
            this.y = 0;
            this.iterate('empty');
          }
        } else {
          if (ways.length > 1) this.stack.push({ x: x, y: y});

          var way = ways[Math.floor(ways.length * Math.random())];

          this.destroy_wall(x, y, way);

          if (way == TOP)    this.y++;
          if (way == BOTTOM) this.y--;
          if (way == RIGHT)  this.x++;
          if (way == LEFT)   this.x--;

          this.iterate();
        }

        break;

      case 'empty':
        document.getElementById('progress').innerHTML = 'Destroying walls';

        var walls = this.rooms[this.y][this.x].walls;
        if (this.y > 0 && walls & BOTTOM && Math.random() < this.openness) this.destroy_wall(this.x, this.y, BOTTOM);
        if (this.x > 0 && walls & LEFT && Math.random() < this.openness) this.destroy_wall(this.x, this.y, LEFT);

        if (this.x == this.width - 1) {
          if (this.y == this.height - 1) {
            this.iterate('done');
          } else {
            this.y++;
            this.x = 0;
            this.iterate();
          }
        } else {
          this.x++;
          this.iterate();
        }

        break;

      case 'done':
        document.getElementById('progress').innerHTML = 'Done';
        break;

      case 'cancel':
        document.getElementById('progress').innerHTML = 'Cancelled';
        break;
    }
  };

  self.iterate = function(stage) {
    if (stage) this.stage = stage;

    var self = this;
    setTimeout(function() { self._iterate() }, this.delay);
  }

  self.generate = function() {
    this.iterate('init');
  }

  self.cancel = function() {
    this.iterate('cancel');
  }

  return self;
}
