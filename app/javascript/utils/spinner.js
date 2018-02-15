let spinnerElements = {};
let spinnerShown = {};

export default {
  show: function(elementOrId) {
    var elementId;
    var element;

    if (typeof elementOrId === 'string') {
      elementId = elementOrId;
    } else if (elementOrId) {
      element = elementOrId;
      if (element.id) {
        elementId = element.id;
      } else {
        elementId = element.id = 'temp-' + tempId++;
      }
    } else {
      elementId = 'cssload-container';
    }

    if (!element) {
      element = document.getElementById(elementId);
      if (!element) {
        element = document.createElement('div');
        element.id = elementId;
        element.innerHTML = '<div class="cssload-container"><div class="cssload-loading"><i></i><i></i></div></div>';
        document.body.appendChild(element);
      }
    }

    spinnerElements[elementId] = element;
    spinnerShown[elementId] = Date.now();

    element.classList.remove('hidden');
  },

  hide: function(elementOrId) {
    var elementId;

    if (typeof elementOrId === 'string') {
      elementId = elementOrId;
    } else if (elementOrId) {
      elementId = elementOrId.id;
    } else {
      elementId = 'cssload-container';
    }

    var element = spinnerElements[elementId];
    var shown = spinnerShown[elementId];

    if (shown) {
      var minTime = 500;
      var now = Date.now();

      if (now - shown > minTime)
        element.classList.add('hidden');
      else {
        setTimeout(function() {
          element.classList.add('hidden');
        }, minTime - (now - shown));
      }
    }
  }
};
