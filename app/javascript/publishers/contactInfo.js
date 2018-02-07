document.addEventListener('DOMContentLoaded', function() {
  var updateContactInfo = document.getElementById('update_contact_info');

  if (!updateContactInfo) {
    return;
  }

  updateContactInfo.addEventListener('submit', function(event) {
    event.preventDefault();
    window.spinner.show();
    window.submitForm('update_contact_info', 'PATCH')
      .then(function() {
        return window.pollUntilSuccess('/publishers/domain_status', 2000, 1000, 10);
      })
      .then(function(response) {
        return response.json();
      })
      .then(function(json) {
        window.spinner.hide();
        if (json.error) {
          window.flash.clear();
          window.flash.append('warning', 'There were errors saving your request:');
          window.flash.append('warning', json.error);
        } else {
          window.location.href = json.next_step;
        }
      })
      .catch(function(e) {
        window.spinner.hide();
        window.flash.clear();
        window.flash.append('warning', 'An unexpected error occurred saving your changes.');
      });
  }, false);
}, false);