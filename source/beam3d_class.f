! beam3d class for QuickPIC Open Source 1.0
! update: 04/18/2016

      module beam3d_class

      use perrors_class
      use parallel_pipe_class
      use spect3d_class
      use fdist3d_class
      use field3d_class
      use part3d_class
      use hdf5io_class
      use mpi
               
      implicit none

      private

      public :: beam3d

      type beam3d

         private

         class(spect3d), pointer, public :: sp => null()
         class(perrors), pointer, public :: err => null()
         class(parallel_pipe), pointer, public :: p => null()
         class(part3d), pointer :: pd         
         contains
         
         generic :: new => init_beam3d
         generic :: del => end_beam3d
         generic :: push => push_beam3d
         generic :: pmv => pmove_beam3d
         generic :: qdp => qdeposit_beam3d  
         generic :: wr => writehdf5_beam3d       
         generic :: wrst => writerst_beam3d       
         generic :: rrst => readrst_beam3d       
         procedure, private :: init_beam3d
         procedure, private :: end_beam3d
         procedure, private :: push_beam3d
         procedure, private :: pmove_beam3d   
         procedure, private :: qdeposit_beam3d, writehdf5_beam3d
         procedure, private :: writerst_beam3d, readrst_beam3d
                  
      end type 

      save      

      character(len=10) :: class = 'beam3d:'
      character(len=128) :: erstr
      
      contains
!
      subroutine init_beam3d(this,pp,perr,psp,pf,fd,qm,qbm,dt,ci,xdim,npmax,nbmax)
      
         implicit none
         
         class(beam3d), intent(inout) :: this
         class(spect3d), intent(in), pointer :: psp
         class(perrors), intent(in), pointer :: perr
         class(parallel_pipe), intent(in), pointer :: pp
         class(fdist3d), intent(in) :: pf
         class(field3d), intent(in) :: fd
         real, intent(in) :: qm, qbm, dt, ci
         integer, intent(in) :: npmax, nbmax, xdim

! local data
         character(len=18), save :: sname = 'init_beam3d:'
         integer :: id, ierr
         integer, dimension(10) :: istat
                  
         this%sp => psp
         this%err => perr
         this%p => pp

         call this%err%werrfl2(class//sname//' started')

         allocate(this%pd)
         call this%pd%new(pp,perr,psp,pf,fd%getrs(),qm,qbm,dt,ci,xdim,npmax,nbmax)
         call this%pmv(fd,1,1,id)
         call MPI_WAIT(id,istat,ierr)
         
         call this%err%werrfl2(class//sname//' ended')

      end subroutine init_beam3d
!
      subroutine end_beam3d(this)
          
         implicit none
         
         class(beam3d), intent(inout) :: this
         character(len=18), save :: sname = 'end_beam3d:'

         call this%err%werrfl2(class//sname//' started')
         call this%pd%del()
         deallocate(this%pd)
         call this%err%werrfl2(class//sname//' ended')
                  
      end subroutine end_beam3d
!      
      subroutine qdeposit_beam3d(this,q)
! deposit the charge density      
      
         implicit none
         
         class(beam3d), intent(in) :: this
         class(field3d), intent(inout) :: q
! local data
         character(len=18), save :: sname = 'qdeposit_beam3d:'
                  
         call this%err%werrfl2(class//sname//' started')
         
         call this%pd%qdp(q%getrs())
                 
         call this%err%werrfl2(class//sname//' ended')
         
      end subroutine qdeposit_beam3d
!      
      subroutine push_beam3d(this,ef,bf,dex,dez,rtag,stag,sid)
      
         implicit none
         
         class(beam3d), intent(inout) :: this
         class(field3d), intent(in) :: ef, bf
         real, intent(in) :: dex, dez
         integer, intent(in) :: rtag, stag
         integer, intent(inout) :: sid         
! local data
         character(len=18), save :: sname = 'partpush'

         call this%err%werrfl2(class//sname//' started')
         
         call this%pd%push(ef%getrs(),bf%getrs(),dex,dez)
         
         call this%pmv(ef,rtag,stag,sid)
         
         call this%err%werrfl2(class//sname//' ended')
         
      end subroutine push_beam3d
!
      subroutine pmove_beam3d(this,fd,rtag,stag,sid)
      
         implicit none
         
         class(beam3d), intent(inout) :: this
         class(field3d), intent(in) :: fd
         integer, intent(in) :: rtag, stag
         integer, intent(inout) :: sid
! local data
         character(len=18), save :: sname = 'pmove:'
         integer :: ny, nz, nvpy, nvpz, nbmax, idds = 2
         integer :: ierr
         real, dimension(4) :: edges
         integer, dimension(2) :: noff         
         integer, dimension(2) :: jsl, jsr, jss
         integer, dimension(9) :: info
         integer :: idimp, npmax, idps, ntmax
         real, dimension(:,:), pointer :: pbuff
         
         call this%err%werrfl2(class//sname//' started')
         
         call this%pd%pmv(fd%getrs(),rtag,stag,sid)
         
         call this%err%werrfl2(class//sname//' ended')
         
      end subroutine pmove_beam3d
!
      subroutine writehdf5_beam3d(this,file,dspl,delta,rtag,stag,id)

         implicit none
         
         class(beam3d), intent(inout) :: this
         class(hdf5file), intent(in) :: file
         real, dimension(3), intent(in) :: delta
         integer, intent(in) :: dspl, rtag, stag
         integer, intent(inout) :: id
! local data
         character(len=18), save :: sname = 'writehdf5_beam3d:'

         call this%err%werrfl2(class//sname//' started')                  
         call this%pd%wr(file,dspl,delta,rtag,stag,id)
         call this%err%werrfl2(class//sname//' ended')
      
      end subroutine writehdf5_beam3d
!            
      subroutine writerst_beam3d(this,file)

         implicit none
         
         class(beam3d), intent(inout) :: this
         class(hdf5file), intent(in) :: file
! local data
         character(len=18), save :: sname = 'writerst_beam3d:'

         call this%err%werrfl2(class//sname//' started')                  
         call this%pd%wrst(file)
         call this%err%werrfl2(class//sname//' ended')
      
      end subroutine writerst_beam3d
!            
      subroutine readrst_beam3d(this,file)

         implicit none
         
         class(beam3d), intent(inout) :: this
         class(hdf5file), intent(in) :: file
! local data
         character(len=18), save :: sname = 'readrst_beam3d:'

         call this%err%werrfl2(class//sname//' started')                  
         call this%pd%rrst(file)
         call this%err%werrfl2(class//sname//' ended')
      
      end subroutine readrst_beam3d
!            
      end module beam3d_class