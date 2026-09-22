// Local preview interactions only; no fetch, analytics, storage, or delivery.
document.querySelectorAll('form').forEach(form => {
  form.addEventListener('submit', event => {
    event.preventDefault();
    const note = form.querySelector('.replica-form-note');
    note.textContent = 'Preview only: nothing was sent or saved. Form delivery will be connected after its destination is verified.';
    note.setAttribute('tabindex', '-1');
    note.focus();
  });
});
document.querySelectorAll('header').forEach(header => {
  const toggle = header.querySelector('.hamburger');
  const menu = header.querySelector('.header__content--mobile');
  if (!toggle || !menu) return;
  if (!menu.querySelector('a')) {
    header.querySelectorAll('.header__content--desktop a').forEach(link => {
      if (link.textContent.trim()) menu.appendChild(link.cloneNode(true));
    });
  }
  function toggleMenu() {
    const open = header.classList.toggle('replica-menu-open');
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');
  }
  toggle.addEventListener('click', toggleMenu);
  toggle.addEventListener('keydown', event => {
    if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); toggleMenu(); }
  });
});
let opener;
function closeModal() {
  document.querySelectorAll('.modal.replica-modal-open').forEach(modal => {
    modal.classList.remove('replica-modal-open'); modal.setAttribute('aria-hidden', 'true');
  });
  if (opener) opener.focus();
}
document.addEventListener('click', event => {
  const link = event.target.closest('a[href^="#"]');
  if (link) {
    const id = link.getAttribute('href').slice(1);
    const modal = id && document.getElementById(id);
    if (modal && modal.classList.contains('modal')) {
      event.preventDefault(); opener = link;
      modal.classList.add('replica-modal-open'); modal.setAttribute('aria-hidden', 'false');
      modal.setAttribute('role', 'dialog'); modal.setAttribute('aria-modal', 'true');
      const first = modal.querySelector('input:not([type=hidden]),button,a[href]');
      if (first) first.focus();
    }
  }
  if (event.target.closest('.close-x') || event.target.classList.contains('modal')) closeModal();
});
document.querySelectorAll('.close-x').forEach(close => {
  close.setAttribute('role', 'button'); close.setAttribute('tabindex', '0'); close.setAttribute('aria-label', 'Close preview dialog');
  close.addEventListener('keydown', event => { if (event.key === 'Enter' || event.key === ' ') closeModal(); });
});
document.addEventListener('keydown', event => {
  if (event.key === 'Escape') closeModal();
  if (event.key !== 'Tab') return;
  const modal = document.querySelector('.modal.replica-modal-open');
  if (!modal) return;
  const focusable = Array.from(modal.querySelectorAll('a[href],button,input:not([type=hidden]),select,textarea,[tabindex="0"]')).filter(el => el.offsetParent !== null);
  const first = focusable[0], last = focusable[focusable.length - 1];
  if (event.shiftKey && document.activeElement === first) {event.preventDefault();last?.focus();}
  else if (!event.shiftKey && document.activeElement === last) {event.preventDefault();first?.focus();}
});
