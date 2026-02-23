    
    
    
    
    // Hide preloader when page is fully loaded
      window.addEventListener('load', function () {
        const preloader = document.getElementById('preloader');
        if (preloader) {
          preloader.style.display = 'none';
        }
      });

      // Fallback to hide preloader if load event doesn't fire
      document.addEventListener('DOMContentLoaded', function () {
        setTimeout(function () {
          const preloader = document.getElementById('preloader');
          if (preloader && preloader.style.display !== 'none') {
            preloader.style.display = 'none';
          }
        }, 2000); // 2 second fallback
      });

      // Initialize DataTable for better table handling
      $(document).ready(function () {
        if ($.fn.DataTable) {
          $('#tranx_table').DataTable({
            "pageLength": 10,
            "ordering": true,
            "responsive": true
          });
        }

        // Ensure all Bootstrap components are properly initialized
        if (typeof bootstrap !== 'undefined') {
          var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
          tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl);
          });
        }
      });

      // Error handling for failed resource loading
      window.addEventListener('error', function (e) {
        if (e.target.tagName === 'SCRIPT' || e.target.tagName === 'LINK') {
          console.warn('Resource failed to load:', e.target.src || e.target.href);
          // Hide preloader in case of resource loading errors
          const preloader = document.getElementById('preloader');
          if (preloader) {
            preloader.style.display = 'none';
          }
        }
      }, true);
